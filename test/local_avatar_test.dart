import 'dart:io';
import 'dart:typed_data';

import 'package:air_quality_monitor/data/local/local_avatar_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporary;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('aq-avatar-');
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  test('Local photos survive a new store, remain UID scoped and replace atomically', () async {
    final store = LocalAvatarStore(temporary);
    expect(await store.readPath('a'), isNull);
    final first = await store.save('a', Uint8List.fromList([1, 2, 3]));
    await store.save('b', Uint8List.fromList([4]));
    final restored = LocalAvatarStore(temporary);
    expect(await restored.readPath('a'), first);
    expect(await File(first).readAsBytes(), [1, 2, 3]);
    final second = await restored.save('a', Uint8List.fromList([5, 6]));
    expect(second, isNot(first));
    expect(await restored.readPath('a'), second);
    expect(await File(second).readAsBytes(), [5, 6]);
    expect(await File(first).exists(), isFalse);
    expect(await File((await store.readPath('b'))!).readAsBytes(), [4]);
    expect(await store.readPath('../a'), isNull);
    expect(await store.readPath('unknown'), isNull);
  });

  test('Invalid photos preserve previous data and incomplete temp files are ignored', () async {
    final store = LocalAvatarStore(temporary);
    final saved = await store.save('a', Uint8List.fromList([1]));
    await File('$saved.tmp').writeAsBytes([8]);
    await expectLater(store.save('a', Uint8List(0)), throwsArgumentError);
    await expectLater(
      store.save('a', Uint8List(5 * 1024 * 1024 + 1)),
      throwsArgumentError,
    );
    expect(await store.readPath('a'), saved);
    expect(await File(saved).readAsBytes(), [1]);
  });
}
