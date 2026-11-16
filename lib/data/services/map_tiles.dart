import 'package:flutter_map/flutter_map.dart';

/// Injectable so widget tests never contact the public tile service.
typedef MapTilesFactory = TileProvider Function();

const osmTileUrl = String.fromEnvironment(
  'MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);
const mapUserAgent =
    'AirQualityMonitor/1.1 (https://github.com/yerkesha-A/air-quality-monitor)';

TileProvider createMapTiles({MapCachingProvider? cache}) => NetworkTileProvider(
  headers: {'User-Agent': mapUserAgent},
  abortObsoleteRequests: true,
  attemptDecodeOfHttpErrorResponses: false,
  cachingProvider:
      cache ??
      BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 64 * 1024 * 1024,
      ),
);
