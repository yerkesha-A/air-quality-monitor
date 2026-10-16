// VM URI and raw traces stay in an ignored directory, never in reports.
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw ArgumentError('Expected private URI file and output directory');
  }
  final uri = (await File(args[0]).readAsString()).trim();
  final socket = uri
      .replaceFirst('http:', 'ws:')
      .replaceFirst('https:', 'wss:');
  final service = await vmServiceConnectUri(
    '${socket.endsWith('/') ? socket : '$socket/'}ws',
  );
  final out = await Directory(args[1]).create(recursive: true);
  try {
    final vm = await service.getVM();
    final isolate = vm.isolates!.firstWhere(
      (i) => i.name == 'main',
      orElse: () => vm.isolates!.first,
    );
    final id = isolate.id!;
    await service.setVMTimelineFlags(['Dart', 'Embedder', 'GC']);
    await service.clearVMTimeline();
    await service.getAllocationProfile(id, gc: true);
    final samples = <Map<String, dynamic>>[];
    for (var i = 0; i < 20; i++) {
      final memory = await service.getMemoryUsage(id);
      samples.add({'elapsedSeconds': i * 3, ...memory.toJson()});
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    final timeline = await service.getVMTimeline();
    await File('${out.path}/vm-timeline.json')
        .writeAsString(jsonEncode(timeline.toJson()));
    await File('${out.path}/memory-samples.json')
        .writeAsString(jsonEncode(samples));
    await service.getAllocationProfile(id, gc: true);
    final after = await service.getMemoryUsage(id);
    await File('${out.path}/memory-after-gc.json')
        .writeAsString(jsonEncode(after.toJson()));
    stdout.writeln(
      'Android VM timeline and 20 memory samples saved privately.',
    );
  } finally {
    await service.dispose();
  }
}
