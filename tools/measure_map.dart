// Real profile-mode map benchmark. URI and raw traces remain private.
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    throw ArgumentError('URI file, output directory, ADB serial');
  }
  final uri = (await File(args[0]).readAsString()).trim();
  final socket = uri
      .replaceFirst('http:', 'ws:')
      .replaceFirst('https:', 'wss:');
  final service = await vmServiceConnectUri(
    '${socket.endsWith('/') ? socket : '$socket/'}ws',
  );
  final out = await Directory(args[1]).create(recursive: true);
  final adb =
      '${Platform.environment['HOME']}/Library/Android/sdk/platform-tools/adb';
  final memory = <Map<String, dynamic>>[];
  var sampling = true;
  try {
    final vm = await service.getVM();
    final isolate = vm.isolates!.firstWhere(
      (i) => i.name == 'main',
      orElse: () => vm.isolates!.first,
    );
    final id = isolate.id!;
    var opened = false;
    for (var attempt = 0; attempt < 60 && !opened; attempt++) {
      try {
        final result = await service.callServiceExtension(
          'ext.aqm.map.open',
          isolateId: id,
        );
        opened = result.json?['ready'] == true;
      } catch (_) {
        // App bootstrap may still be registering the QA extension.
      }
      if (!opened) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    if (!opened) {
      throw StateError('Real map was not ready for profiling');
    }
    await Future<void>.delayed(const Duration(seconds: 8));
    final viewport = await service.callServiceExtension(
      'ext.aqm.map.viewport',
      isolateId: id,
    );
    await File('${out.path}/viewport.json')
        .writeAsString(jsonEncode(viewport.json));
    await service.setVMTimelineFlags(['Dart', 'Embedder', 'GC']);
    await service.clearVMTimeline();
    await service.getAllocationProfile(id, gc: true);
    await service.callServiceExtension('ext.aqm.frames.start', isolateId: id);
    final watch = Stopwatch()..start();
    final samplingTask = () async {
      while (sampling) {
        memory.add({
          'elapsedMs': watch.elapsedMilliseconds,
          ...(await service.getMemoryUsage(id)).toJson(),
        });
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }();
    Future<void> input(List<String> command, [int pause = 450]) async {
      final r = await Process.run(adb, [
        '-s',
        args[2],
        'shell',
        'input',
        ...command,
      ]);
      if (r.exitCode != 0) throw StateError('ADB gesture failed');
      await Future<void>.delayed(Duration(milliseconds: pause));
    }

    // Same 720x1600 AVD, same physical gestures inside both old/new viewports.
    for (var cycle = 0; cycle < 3; cycle++) {
      await input(['swipe', '460', '700', '260', '700', '600'], 350);
      await input(['swipe', '260', '700', '460', '700', '600'], 350);
      await input(['swipe', '400', '790', '400', '610', '600'], 350);
      await input(['swipe', '400', '610', '400', '790', '600'], 350);
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    final frames = await service.callServiceExtension(
      'ext.aqm.frames.stop',
      isolateId: id,
    );
    sampling = false;
    await samplingTask;
    final timeline = await service.getVMTimeline();
    await File('${out.path}/frame-timings.json')
        .writeAsString(jsonEncode(frames.json));
    await File('${out.path}/memory-samples.json')
        .writeAsString(jsonEncode(memory));
    await File('${out.path}/vm-timeline.json')
        .writeAsString(jsonEncode(timeline.toJson()));
    await service.getAllocationProfile(id, gc: true);
    final after = await service.getMemoryUsage(id);
    await File('${out.path}/memory-after-gc.json')
        .writeAsString(jsonEncode(after.toJson()));
    stdout.writeln(
      'Real Android FrameTiming, timeline and memory samples saved; ${watch.elapsed.inSeconds}s scenario.',
    );
  } finally {
    sampling = false;
    await service.dispose();
  }
}
