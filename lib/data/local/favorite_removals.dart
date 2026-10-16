import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Account-scoped durable explicit deletions. Versions keep a removal made
/// during an upload from being acknowledged by that older upload.
class FavoriteRemovals {
  FavoriteRemovals(this.preferences, this.uid);
  final SharedPreferences preferences;
  final String uid;
  String get _key => 'favorite_removals_v1_$uid';
  Map<String, int> snapshot() {
    final raw = preferences.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((id, version) => MapEntry(id, version as int));
  }

  Future<void> record(String id, {required bool favorite}) async {
    final changes = snapshot();
    if (favorite) {
      changes.remove(id);
    } else {
      changes[id] = DateTime.now().microsecondsSinceEpoch;
    }
    await preferences.setString(_key, jsonEncode(changes));
  }

  Future<void> acknowledge(Map<String, int> sent) async {
    final changes = snapshot();
    for (final entry in sent.entries) {
      if (changes[entry.key] == entry.value) changes.remove(entry.key);
    }
    await preferences.setString(_key, jsonEncode(changes));
  }
}
