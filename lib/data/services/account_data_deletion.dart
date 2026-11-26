/// A deletion barrier is installed before removing any documents. Security
/// rules use it to reject writes from other devices with still-valid ID tokens.
abstract interface class AccountDataGateway {
  Future<void> begin(String uid);
  Future<List<String>> page(String uid, String collection, int limit);
  Future<void> remove(String uid, String collection, List<String> ids);
  Future<void> removeProfile(String uid);
}

class AccountDataDeletion {
  const AccountDataDeletion(this.gateway);
  final AccountDataGateway gateway;
  static const collections = [
    'devices',
    'favorites',
    'notifications',
    'alertClaims',
  ];

  Future<void> erase(String uid) async {
    if (uid.isEmpty) throw ArgumentError.value(uid, 'uid');
    // Failure (including old server rules) stops here, before any data removal.
    await gateway.begin(uid);
    for (final collection in collections) {
      while (true) {
        final ids = await gateway.page(uid, collection, 200);
        if (ids.isEmpty) break;
        await gateway.remove(uid, collection, ids);
      }
    }
    await gateway.removeProfile(uid);
  }
}
