import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/air_quality.dart';
part 'air_dto.g.dart';

@JsonSerializable()
class PlaceDto {
  const PlaceDto({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country = '',
    this.region = '',
  });
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String region;
  factory PlaceDto.fromJson(Map<String, dynamic> json) =>
      _$PlaceDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceDtoToJson(this);
  Place toEntity() => Place(
    id: id,
    name: name,
    latitude: latitude,
    longitude: longitude,
    country: country,
    region: region,
  );
  factory PlaceDto.fromEntity(Place p) => PlaceDto(
    id: p.id,
    name: p.name,
    latitude: p.latitude,
    longitude: p.longitude,
    country: p.country,
    region: p.region,
  );
}

@JsonSerializable()
class AirPayloadDto {
  const AirPayloadDto({this.current, this.hourly, this.utcOffsetSeconds = 0});
  final Map<String, dynamic>? current;
  final Map<String, dynamic>? hourly;
  @JsonKey(name: 'utc_offset_seconds')
  final int utcOffsetSeconds;
  factory AirPayloadDto.fromJson(Map<String, dynamic> json) =>
      _$AirPayloadDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AirPayloadDtoToJson(this);

  AirReport? toEntity(Place place, DateTime fetchedAt) {
    final now = current;
    final epoch = now?['time'];
    if (now == null || epoch is! num) return null;
    final sample = _point(epoch, now);
    if (sample.aqi == null) return null;
    final hours = hourly;
    final points = <AirPoint>[];
    if (hours != null && hours['time'] is List) {
      final times = hours['time'] as List;
      for (var i = 0; i < times.length; i++) {
        final time = times[i];
        if (time is! num) continue;
        final values = <String, dynamic>{};
        for (final key in ['us_aqi', ...pollutantLabels.keys]) {
          final array = hours[key];
          values[key] = array is List && i < array.length ? array[i] : null;
        }
        points.add(_point(time, values));
      }
    }
    return AirReport(
      place: place,
      current: sample,
      forecast: points,
      fetchedAt: fetchedAt,
      utcOffsetSeconds: utcOffsetSeconds,
    );
  }

  static AirPoint _point(num epoch, Map<String, dynamic> raw) => AirPoint(
    time: DateTime.fromMillisecondsSinceEpoch(
      (epoch * 1000).round(),
      isUtc: true,
    ),
    values: {
      for (final key in ['us_aqi', ...pollutantLabels.keys])
        key: _number(raw[key]),
    },
  );
  static double? _number(dynamic value) =>
      value is num && value.isFinite && value >= 0 ? value.toDouble() : null;
}

@JsonSerializable()
class GeocodingDto {
  const GeocodingDto({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
  });
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin1;
  factory GeocodingDto.fromJson(Map<String, dynamic> json) =>
      _$GeocodingDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GeocodingDtoToJson(this);
  Place toEntity() => Place(
    id: id.toString(),
    name: name,
    latitude: latitude,
    longitude: longitude,
    country: country ?? '',
    region: admin1 ?? '',
  );
}
