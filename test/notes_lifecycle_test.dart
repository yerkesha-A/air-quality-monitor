import 'dart:async';

import 'package:air_quality_monitor/data/local/local_store.dart';
import 'package:air_quality_monitor/presentation/bloc/air_bloc.dart';
import 'package:air_quality_monitor/presentation/screens/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'support/test_dependencies.dart';

class _Picker extends Mock implements ImagePicker {}

void main() {
  Future<MockLocalStore> show(WidgetTester tester, ImagePicker picker) async {
    final dependencies = testDependencies(selected: true);
    final bloc = AirBloc(dependencies.air, dependencies.places)
      ..add(const LoadAir(fixturePlace));
    addTearDown(bloc.close);
    final store = dependencies.store as MockLocalStore;
    await tester.pumpWidget(
      RepositoryProvider<LocalStore>.value(
        value: store,
        child: BlocProvider.value(
          value: bloc,
          child: MaterialApp(home: NotesScreen(imagePicker: picker)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('iOS notes never call Android lost-camera recovery', (
    tester,
  ) async {
    final picker = _Picker();
    await show(tester, picker);
    verifyNever(() => picker.retrieveLostData());
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Android camera recovery failure leaves notes usable', (
    tester,
  ) async {
    final picker = _Picker();
    when(() => picker.retrieveLostData())
        .thenThrow(StateError('recovery unavailable'));
    await show(tester, picker);
    verify(() => picker.retrieveLostData()).called(1);
    expect(find.text('Заметки о месте'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'Saving a note after the screen closes does not notify disposed state',
    (tester) async {
      final picker = _Picker();
      when(() => picker.retrieveLostData())
          .thenAnswer((_) async => LostDataResponse.empty());
      final store = await show(tester, picker);
      final pending = Completer<int>();
      when(() => store.addNote(any(), 'Regression note', null))
          .thenAnswer((_) => pending.future);
      await tester.enterText(find.byType(TextField), 'Regression note');
      await tester.scrollUntilVisible(
        find.text('Сохранить'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(1);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
