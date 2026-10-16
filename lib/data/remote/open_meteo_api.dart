import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/air_quality.dart';
import '../../domain/repositories/air_repository.dart';
import '../models/air_dto.dart';

class OpenMeteoApi {
  OpenMeteoApi(this.client, {this.timeout = const Duration(seconds: 18)});
  final http.Client client;
  final Duration timeout;
  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await client.get(uri).timeout(timeout);
      if (response.statusCode == 429) {
        throw const AirFailure(
          'Слишком много запросов. Попробуйте чуть позже.',
        );
      }
      if (response.statusCode != 200) {
        throw AirFailure(
          'Источник данных недоступен (HTTP ${response.statusCode}).',
        );
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic> || json['error'] == true) {
        throw const AirFailure('Источник вернул некорректные данные.');
      }
      return json;
    } on AirFailure {
      rethrow;
    } on TimeoutException {
      throw const AirFailure('Сервер не ответил вовремя. Повторите запрос.');
    } on SocketException {
      throw const AirFailure(
        'Не удалось установить сетевое соединение. Проверьте подключение.',
      );
    } on http.ClientException {
      throw const AirFailure('Не удалось подключиться к источнику данных.');
    } on FormatException {
      throw const AirFailure('Не удалось прочитать ответ сервера.');
    }
  }

  Future<AirPayloadDto> air(Place place) async {
    final variables = ['us_aqi', ...pollutantLabels.keys].join(',');
    final json = await _get(
      Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        'latitude': place.latitude.toString(),
        'longitude': place.longitude.toString(),
        'current': variables,
        'hourly': variables,
        'forecast_days': '3',
        'timeformat': 'unixtime',
        'timezone': 'auto',
      }),
    );
    try {
      return AirPayloadDto.fromJson(json);
    } catch (_) {
      throw const AirFailure('Некорректная структура данных о воздухе.');
    }
  }

  Future<List<Place>> search(String query) async {
    if (query.trim().length < 2) return [];
    final json = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': query.trim(),
        'count': '15',
        'language': 'ru',
        'format': 'json',
      }),
    );
    final results = json['results'];
    if (results == null) return [];
    if (results is! List) {
      throw const AirFailure('Некорректный ответ поиска городов.');
    }
    try {
      return results
          .map(
            (r) => GeocodingDto.fromJson(r as Map<String, dynamic>).toEntity(),
          )
          .toList();
    } catch (_) {
      throw const AirFailure('Не удалось прочитать результаты поиска.');
    }
  }

  Future<Place> resolve(String id) async {
    if (int.tryParse(id) == null) {
      throw const AirFailure('Город по этой ссылке не найден.');
    }
    final json = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/get', {
        'id': id,
        'language': 'ru',
      }),
    );
    try {
      return GeocodingDto.fromJson(json).toEntity();
    } catch (_) {
      throw const AirFailure('Не удалось открыть город по ссылке.');
    }
  }
}
