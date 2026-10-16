import 'package:air_quality_monitor/data/local/favorite_removals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Pending deletes survive restart, are account scoped and version acknowledged', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = FavoriteRemovals(prefs, 'account-a');
    await queue.record('city', favorite: false);
    final sent = queue.snapshot();
    expect(FavoriteRemovals(prefs, 'account-a').snapshot(), sent);
    expect(FavoriteRemovals(prefs, 'account-b').snapshot(), isEmpty);
    await queue.record('city', favorite: true);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await queue.record('city', favorite: false);
    await queue.acknowledge(sent);
    expect(queue.snapshot().keys, contains('city'));
    await queue.acknowledge(queue.snapshot());
    expect(queue.snapshot(), isEmpty);
  });
}
