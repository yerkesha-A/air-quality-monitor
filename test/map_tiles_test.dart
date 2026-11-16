import 'package:air_quality_monitor/data/services/map_tiles.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Production provider accepts TileLayer headers and identifies the app',
    () {
      final provider = createMapTiles(
        cache: const DisabledMapCachingProvider(),
      );
      addTearDown(provider.dispose);
      // TileLayer calls putIfAbsent, even when our User-Agent already exists.
      // A const/unmodifiable headers map crashes on the real Android path.
      expect(
        () => TileLayer(
          tileProvider: provider,
          urlTemplate: osmTileUrl,
          userAgentPackageName: 'com.example.air_quality_monitor',
        ),
        returnsNormally,
      );
      expect(provider.headers['User-Agent'], mapUserAgent);
      expect(
        provider.headers.keys.any((k) => k.toLowerCase() == 'cache-control'),
        isFalse,
      );
      expect((provider as NetworkTileProvider).abortObsoleteRequests, isTrue);
    },
  );
}
