import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:campus_notify/features/announcements/presentation/pages/announcement_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:vm_service/vm_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('PROFILE_STAGE', defaultValue: 'after');

  testWidgets('Scroll, detail, kembali, dan refresh', (tester) async {
    final info = await developer.Service.getInfo();
    final uri = info.serverWebSocketUri!;
    final service = await vmServiceConnectUri(uri.toString());
    final vm = await service.getVM();
    final isolate = vm.isolates!.first.id!;
    final output = Directory('../docs/profiling')..createSync(recursive: true);

    await tester.pumpWidget(const MaterialApp(home: AnnouncementListPage()));
    await tester.pumpAndSettle();
    final memoryBefore = await service.getAllocationProfile(isolate, gc: true);
    File('${output.path}/$stage-memory-before.json')
        .writeAsStringSync(jsonEncode(memoryBefore.toJson()));
    await saveHeap(
      service,
      vm.isolates!.first,
      '${output.path}/$stage-heap-before',
    );
    const manual = bool.fromEnvironment('PROFILE_MANUAL');
    if (manual) await waitForFile('${output.path}/$stage-start');
    final timings = <FrameTiming>[];
    void record(List<FrameTiming> values) => timings.addAll(values);
    SchedulerBinding.instance.addTimingsCallback(record);

    await binding.traceAction(() async {
      // Buka ulang daftar agar biaya build pertama ikut tercatat.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const MaterialApp(home: AnnouncementListPage()));
      await tester.pumpAndSettle();
      final list = find.byKey(const Key('announcement-list'));
      for (var i = 0; i < 5; i++) {
        await tester.fling(list, const Offset(0, -1200), 2500);
        await tester.pumpAndSettle();
      }
      tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)).first,
          )
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.fling(list, const Offset(0, 1200), 2500);
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      final refresh = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pumpAndSettle();
      await refresh;
      await tester.pumpAndSettle();
      expect(find.textContaining('Pembaruan:'), findsOneWidget);
      expect(find.text('Pembaruan: 0'), findsNothing);
    });
    await Future<void>.delayed(const Duration(seconds: 1));
    SchedulerBinding.instance.removeTimingsCallback(record);
    final memoryAfter = await service.getAllocationProfile(isolate, gc: true);
    File('${output.path}/$stage-memory-after.json')
        .writeAsStringSync(jsonEncode(memoryAfter.toJson()));
    File('${output.path}/$stage-timeline.json')
        .writeAsStringSync(jsonEncode(binding.reportData!['timeline']));
    File('${output.path}/$stage-frames.json').writeAsStringSync(
      jsonEncode(
        timings
            .map(
              (t) => {
                'build_us': t.buildDuration.inMicroseconds,
                'raster_us': t.rasterDuration.inMicroseconds,
                'total_us': t.totalSpan.inMicroseconds,
              },
            )
            .toList(),
      ),
    );
    await saveHeap(
      service,
      vm.isolates!.first,
      '${output.path}/$stage-heap-after',
    );
    File('${output.path}/$stage-ready').writeAsStringSync('done');
    if (manual) await waitForFile('${output.path}/$stage-finish');
    await service.dispose();
  });
}

Future<void> waitForFile(String path) async {
  for (var i = 0; i < 300 && !File(path).existsSync(); i++) {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

Future<void> saveHeap(
  VmService service,
  IsolateRef isolate,
  String path,
) async {
  final heap = await HeapSnapshotGraph.getSnapshot(service, isolate);
  File('$path.json').writeAsStringSync(
    jsonEncode({
      'shallowSize': heap.shallowSize,
      'capacity': heap.capacity,
      'objects': heap.objects.length,
    }),
  );
  File('$path.bin.gz').writeAsBytesSync(
    gzip.encode([
      for (final chunk in heap.toChunks())
        ...chunk.buffer.asUint8List(chunk.offsetInBytes, chunk.lengthInBytes),
    ]),
  );
}
