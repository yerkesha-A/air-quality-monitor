// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'air_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceDto _$PlaceDtoFromJson(Map<String, dynamic> json) => PlaceDto(
  id: json['id'] as String,
  name: json['name'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  country: json['country'] as String? ?? '',
  region: json['region'] as String? ?? '',
);

Map<String, dynamic> _$PlaceDtoToJson(PlaceDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'country': instance.country,
  'region': instance.region,
};

AirPayloadDto _$AirPayloadDtoFromJson(Map<String, dynamic> json) =>
    AirPayloadDto(
      current: json['current'] as Map<String, dynamic>?,
      hourly: json['hourly'] as Map<String, dynamic>?,
      utcOffsetSeconds: (json['utc_offset_seconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AirPayloadDtoToJson(AirPayloadDto instance) =>
    <String, dynamic>{
      'current': instance.current,
      'hourly': instance.hourly,
      'utc_offset_seconds': instance.utcOffsetSeconds,
    };

GeocodingDto _$GeocodingDtoFromJson(Map<String, dynamic> json) => GeocodingDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  country: json['country'] as String?,
  admin1: json['admin1'] as String?,
);

Map<String, dynamic> _$GeocodingDtoToJson(GeocodingDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'country': instance.country,
      'admin1': instance.admin1,
    };
