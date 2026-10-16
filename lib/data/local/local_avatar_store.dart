import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Private app documents, scoped to Firebase UID. No cloud upload or cache folder.
class LocalAvatarStore {
  LocalAvatarStore(this.directory);
  final Directory directory;

  static Future<LocalAvatarStore> open() async => LocalAvatarStore(
    Directory(
      path.join(
        (await getApplicationDocumentsDirectory()).path,
        'profile_photos',
      ),
    ),
  );

  Directory _account(String uid) {
    if (uid.isEmpty) throw ArgumentError.value(uid, 'uid');
    return Directory(
      path.join(directory.path, base64Url.encode(utf8.encode(uid))),
    );
  }

  Future<String?> readPath(String uid) async {
    final folder = _account(uid);
    if (!await folder.exists()) return null;
    final files = await folder
        .list()
        .where(
          (entry) =>
              entry is File &&
              RegExp(r'^avatar-\d+\.jpg$').hasMatch(path.basename(entry.path)),
        )
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files.isEmpty ? null : files.first.path;
  }

  Future<String> save(String uid, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw ArgumentError('Photo must contain between 1 byte and 5 MB');
    }
    final folder = await _account(uid).create(recursive: true);
    final name = 'avatar-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final temporary = File(path.join(folder.path, '$name.tmp'));
    await temporary.writeAsBytes(bytes, flush: true);
    final saved = await temporary.rename(path.join(folder.path, name));
    // Immutable image paths also invalidate Flutter's decoded image cache.
    // Remove only older photos belonging to this account, after a successful save.
    await for (final entry in folder.list()) {
      if (entry is File &&
          entry.path != saved.path &&
          RegExp(r'^avatar-\d+\.jpg$').hasMatch(path.basename(entry.path))) {
        try {
          await entry.delete();
        } on FileSystemException {
          /* Retry next save. */
        }
      }
    }
    return saved.path;
  }
}
