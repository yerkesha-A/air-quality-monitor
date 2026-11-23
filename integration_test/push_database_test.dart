import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/first_launch.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Closing background SQLite connection keeps UI database usable', (
    tester,
  ) async {
    await requireIsolatedAndroid();
    final ui = await LocalStore.open();
    final background = await LocalStore.open(singleInstance: false);
    final id =
        'qa-independent-connection-${DateTime.now().microsecondsSinceEpoch}';
    try {
      await background.recordAlert(
        id: id,
        title: 'QA SQLite connection',
        body: 'Independent background handle',
        source: 'push',
      );
      await background.database.close();
      final rows = await ui.database.query(
        'alerts',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows.single['id'], id);
      expect(await ui.database.rawQuery('PRAGMA integrity_check'), [
        {'integrity_check': 'ok'},
      ]);
    } finally {
      if (background.database.isOpen) await background.database.close();
      await ui.database.close();
    }
  });
}
