import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:air_quality_monitor/main.dart' as app;
import 'package:air_quality_monitor/data/services/device_service.dart';
import 'package:air_quality_monitor/data/local/local_avatar_store.dart';
import 'package:air_quality_monitor/presentation/providers/auth_controller.dart';
import 'package:air_quality_monitor/presentation/screens/home_screen.dart';
import 'package:air_quality_monitor/presentation/widgets/account_avatar.dart';

Future<void> until(WidgetTester tester, bool Function() ready) async {
  final end = DateTime.now().add(const Duration(seconds: 120));
  while (!ready() && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 150));
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
  expect(
    ready(),
    isTrue,
    reason: 'Waiting for native UI / Android result timed out',
  );
}

Future<Map<String, Object>> verifyDiskCache() async {
  // Only an isolated integration fixture, never an application avatar or AQI.
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
      .drawRect(const Rect.fromLTWH(0, 0, 8, 8), Paint()..color = Colors.teal);
  final picture = recorder.endRecording();
  final image = await picture.toImage(8, 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  final bytes = data!.buffer.asUint8List();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  var requests = 0;
  server.listen((request) async {
    requests++;
    request.response.headers.contentType = ContentType('image', 'png');
    request.response.headers.set(
      HttpHeaders.cacheControlHeader,
      'max-age=86400',
    );
    request.response.add(bytes);
    await request.response.close();
  });
  final url = 'http://127.0.0.1:${server.port}/integration-only.png';
  final provider = CachedNetworkImageProvider(
    url,
    cacheKey: 'weeks10-native-${server.port}',
  );
  Future<void> resolve() async {
    final done = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (value, _) {
        value.dispose();
        stream.removeListener(listener);
        if (!done.isCompleted) done.complete();
      },
      onError: (Object error, StackTrace? stack) {
        stream.removeListener(listener);
        if (!done.isCompleted) done.completeError(error, stack);
      },
    );
    stream.addListener(listener);
    await done.future.timeout(const Duration(seconds: 30));
  }

  try {
    await resolve();
    await server.close(force: true);
    // Evict this fixture from memory only. Disk cache/user SQLite is not cleared.
    await provider.evict();
    await resolve();
    expect(
      requests,
      1,
      reason: 'Second decode must come from the real disk cache with server stopped',
    );
    return {'httpRequests': requests, 'diskCacheAfterServerStop': true};
  } finally {
    await server.close(force: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Isolated Android SDK channel, disk cache and camera/gallery profile workflow',
    (tester) async {
      expect(const bool.fromEnvironment('ALLOW_ISOLATED_WEEKS_TEST'), isTrue);
      final docs = await getApplicationDocumentsDirectory();
      expect(
        await File('${docs.path}/weeks09_11_isolated').exists(),
        isTrue,
        reason:
            'Refuse to run on the owner/main AVD without an isolated marker',
      );
      final info = await const DeviceService().info();
      expect(info['available'], isTrue);
      expect(info['sdk'], greaterThanOrEqualTo(24));
      expect(info['model'], isNotEmpty);
      if (info['battery'] != null) {
        expect(info['battery'], inInclusiveRange(0, 100));
      }
      await expectLater(
        const MethodChannel('air_quality_monitor/device')
            .invokeMethod<void>('unknownVerificationMethod'),
        throwsA(isA<MissingPluginException>()),
      );
      final cache = await tester.runAsync(verifyDiskCache);
      expect(cache?['diskCacheAfterServerStop'], isTrue);
      await app.main();
      await until(tester, () => find.byType(HomeScreen).evaluate().isNotEmpty);
      if (const bool.fromEnvironment('VERIFY_NATIVE_RESTART')) {
        final previous = jsonDecode(
          await File('${docs.path}/weeks-native-verification.json')
              .readAsString(),
        ) as Map<String, dynamic>;
        expect(FirebaseAuth.instance.currentUser?.uid, previous['uid']);
        final auth = tester
            .element(find.byType(HomeScreen))
            .read<AuthController>();
        await until(tester, () => auth.account?.localPhotoPath != null);
        expect(auth.account!.localPhotoPath, previous['avatarPath']);
        expect(await File(auth.account!.localPhotoPath!).exists(), isTrue);
        previous['sessionAndPhotoAfterRestart'] = true;
        await File('${docs.path}/weeks-native-verification.json')
            .writeAsString(jsonEncode(previous));
        return;
      }
      const email = String.fromEnvironment('FIREBASE_TEST_EMAIL');
      const password = String.fromEnvironment('FIREBASE_TEST_PASSWORD');
      expect(email, isNotEmpty);
      expect(password, isNotEmpty);
      await tester.runAsync(
        () => FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
      final context = tester.element(find.byType(HomeScreen));
      final auth = context.read<AuthController>();
      await until(tester, () => auth.account != null);
      GoRouter.of(context).push('/account');
      await until(
        tester,
        () => find.text('Изменить фото').evaluate().isNotEmpty,
      );
      final uid = auth.account!.id;
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      expect(profile.exists, isTrue);
      final push = Completer<void>();
      final subscription = FirebaseMessaging.onMessage.listen((message) {
        if (message.data['verification'] == 'stage2-android' &&
            !push.isCompleted) {
          push.complete();
        }
      });
      final token = await FirebaseMessaging.instance.getToken();
      expect(token, isNotEmpty);
      await File('${docs.path}/weeks-fcm-token').writeAsString(token!);
      await tester.runAsync(
        () => push.future.timeout(const Duration(seconds: 90)),
      );
      await subscription.cancel();
      await File('${docs.path}/weeks-fcm-token').delete();
      await File('${docs.path}/weeks-native-verification.json')
          .writeAsString(jsonEncode({'phase': 'camera-pending'}));
      // Host helper drives Android's real camera/picker; no mocked image_picker here.
      final previousPhoto = auth.account?.localPhotoPath;
      await tester.tap(find.text('Изменить фото'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сделать снимок'));
      await tester.pump();
      await until(
        tester,
        () =>
            auth.account?.localPhotoPath != null &&
            auth.account?.localPhotoPath != previousPhoto &&
            !auth.busy,
      );
      final first = File(auth.account!.localPhotoPath!);
      expect(await first.length(), greaterThan(100));
      expect(find.byType(AccountAvatar), findsOneWidget);
      final reopened = await LocalAvatarStore.open();
      expect(
        await reopened.readPath(auth.account!.id),
        auth.account!.localPhotoPath,
      );
      await File('${docs.path}/weeks-native-verification.json').writeAsString(
        jsonEncode({
          'cameraPath': first.path,
          'uid': auth.account!.id,
          'cache': cache,
          'sdk': info['sdk'],
          'channel': true,
          'firestoreServer': true,
          'fcmForeground': true,
        }),
      );
      await until(
        tester,
        () =>
            !auth.busy &&
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();
      // Import a copy of this real camera photo into test AVD Pictures from the host.
      // The system picker is then opened and controlled externally.
      await tester.tap(find.text('Изменить фото'));
      await tester.pumpAndSettle();
      await until(
        tester,
        () => find.text('Выбрать из галереи').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Выбрать из галереи'));
      await tester.pump();
      await until(tester, () => auth.account?.localPhotoPath != first.path);
      expect(
        await File(auth.account!.localPhotoPath!).length(),
        greaterThan(100),
      );
      await File('${docs.path}/weeks-native-verification.json').writeAsString(
        jsonEncode({
          'camera': true,
          'gallery': true,
          'uid': auth.account!.id,
          'avatarPath': auth.account!.localPhotoPath,
          'cache': cache,
          'sdk': info['sdk'],
          'channel': true,
          'firestoreServer': true,
          'fcmForeground': true,
        }),
      );
    },
    timeout: const Timeout(Duration(minutes: 7)),
  );
}
