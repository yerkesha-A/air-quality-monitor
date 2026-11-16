import 'package:air_quality_monitor/core/support/contact.dart';
import 'package:air_quality_monitor/presentation/screens/account_deletion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Deletion request is an addressed draft, contains no account credentials',
    () {
      final uri = accountDeletionEmail();
      expect(uri.scheme, 'mailto');
      expect(uri.path, supportEmail);
      expect(
        uri.queryParameters['subject'],
        'Удаление аккаунта Air Quality Monitor',
      );
      expect(
        uri.queryParameters['body'],
        contains('Пароль и коды подтверждения не прилагаю'),
      );
      expect(
        uri.query,
        isNot(contains('+')),
      ); // mail clients must receive spaces correctly
    },
  );
  testWidgets(
    'Unavailable mail app keeps clear instructions and never claims deletion',
    (tester) async {
      Uri? draft;
      await tester.pumpWidget(
        MaterialApp(
          home: AccountDeletionScreen(
            launcher: (uri) async {
              draft = uri;
              return false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Составить запрос'));
      await tester.tap(find.text('Составить запрос'));
      await tester.pumpAndSettle();
      expect(draft?.scheme, 'mailto');
      expect(
        find.textContaining('Почтовое приложение недоступно.'),
        findsOneWidget,
      );
      expect(find.text('Аккаунт удалён'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
