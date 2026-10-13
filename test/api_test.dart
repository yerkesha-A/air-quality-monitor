import 'dart:convert';

import 'package:air_quality_monitor/data/models/air_dto.dart';
import 'package:air_quality_monitor/data/remote/open_meteo_api.dart';
import 'package:air_quality_monitor/domain/entities/air_quality.dart';
import 'package:air_quality_monitor/domain/repositories/air_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const testPlace = Place(
  id: '1',
  name: 'Алматы',
  latitude: 43.2,
  longitude: 76.9,
);
Map<String, dynamic> validPayload() => {
  'utc_offset_seconds': 18000,
  'current': {'time': 1791864000, 'us_aqi': 42, 'pm2_5': 9.1},
  'hourly': {
    'time': [1791864000, 1791867600, 1791871200],
    'us_aqi': [42, null, 70],
    'pm2_5': [9.1],
  },
};
void main() {
  test(
    'DTO tolerates missing pollutants and short arrays; serializes cache',
    () {
      final dto = AirPayloadDto.fromJson(validPayload());
      final report = dto.toEntity(testPlace, DateTime.utc(2026));
      expect(report!.current.aqi, 42);
      expect(report.current.values['ozone'], isNull);
      expect(report.forecast[1].values['pm2_5'], isNull);
      expect(report.forecast[2].aqi, 70);
      expect(
        AirPayloadDto.fromJson(dto.toJson())
            .toEntity(testPlace, DateTime.utc(2026))!
            .current
            .aqi,
        42,
      );
      expect(
        PlaceDto.fromJson(PlaceDto.fromEntity(testPlace).toJson())
            .toEntity()
            .name,
        'Алматы',
      );
      expect(
        GeocodingDto.fromJson({
          'id': 1,
          'name': 'Алматы',
          'latitude': 43.2,
          'longitude': 76.9,
        }).toEntity().country,
        '',
      );
    },
  );
  test('No invented AQI for empty, null or invalid responses', () {
    expect(
      const AirPayloadDto().toEntity(testPlace, DateTime.utc(2026)),
      isNull,
    );
    for (final value in [null, -5, '42', double.nan]) {
      expect(
        AirPayloadDto(current: {'time': 1791864000, 'us_aqi': value})
            .toEntity(testPlace, DateTime.utc(2026)),
        isNull,
      );
    }
  });
  test('API sends coordinates and US AQI with unix instants', () async {
    final api = OpenMeteoApi(
      MockClient((request) async {
        expect(request.url.queryParameters['timeformat'], 'unixtime');
        expect(request.url.queryParameters['current'], contains('us_aqi'));
        expect(request.url.queryParameters['latitude'], '43.2');
        return http.Response(jsonEncode(validPayload()), 200);
      }),
    );
    expect((await api.air(testPlace)).current!['us_aqi'], 42);
  });
  test(
    'Search supports unicode, absent results and validates malformed rows',
    () async {
      final api = OpenMeteoApi(
        MockClient((request) async {
          expect(request.url.queryParameters['name'], 'Алматы');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'results': [
                  {
                    'id': 1,
                    'name': 'Алматы',
                    'latitude': 43.2,
                    'longitude': 76.9,
                    'country': 'Казахстан',
                  },
                ],
              }),
            ),
            200,
          );
        }),
      );
      expect((await api.search(' Алматы ')).single.name, 'Алматы');
      expect(await api.search('А'), isEmpty);
      expect(
        await OpenMeteoApi(MockClient((_) async => http.Response('{}', 200)))
            .search('Алматы'),
        isEmpty,
      );
      for (final body in ['{"results":1}', '{"results":[{"id":"bad"}]}']) {
        await expectLater(
          OpenMeteoApi(MockClient((_) async => http.Response(body, 200)))
              .search('Алматы'),
          throwsA(isA<AirFailure>()),
        );
      }
    },
  );
  test(
    'HTTP, rate limit, timeout and malformed JSON become actionable errors',
    () async {
      for (final status in [429, 500, 403]) {
        await expectLater(
          OpenMeteoApi(MockClient((_) async => http.Response('{}', status)))
              .air(testPlace),
          throwsA(isA<AirFailure>()),
        );
      }
      for (final body in ['broken', '[]', '{"error":true}', '{"current":1}']) {
        await expectLater(
          OpenMeteoApi(MockClient((_) async => http.Response(body, 200)))
              .air(testPlace),
          throwsA(isA<AirFailure>()),
        );
      }
      await expectLater(
        OpenMeteoApi(
          MockClient((_) async => throw http.ClientException('offline')),
        ).air(testPlace),
        throwsA(isA<AirFailure>()),
      );
      await expectLater(
        OpenMeteoApi(
          MockClient((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return http.Response('{}', 200);
          }),
          timeout: const Duration(milliseconds: 5),
        ).air(testPlace),
        throwsA(isA<AirFailure>()),
      );
    },
  );
  test(
    'City IDs resolve through the documented endpoint; malformed IDs fail',
    () async {
      final api = OpenMeteoApi(
        MockClient((request) async {
          expect(request.url.path, '/v1/get');
          expect(request.url.queryParameters['id'], '1');
          return http.Response(
            '{"id":1,"name":"City","latitude":43.2,"longitude":76.9}',
            200,
          );
        }),
      );
      expect((await api.resolve('1')).id, '1');
      await expectLater(api.resolve('invalid'), throwsA(isA<AirFailure>()));
    },
  );
}
