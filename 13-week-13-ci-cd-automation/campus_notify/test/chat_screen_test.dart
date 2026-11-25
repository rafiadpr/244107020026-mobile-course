import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/features/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAiService extends AiService {
  final responses = StreamController<String>.broadcast();
  int calls = 0;

  @override
  Stream<String> askStream(String question) {
    calls++;
    return responses.stream;
  }
}

final screenshotKey = GlobalKey();

Future<void> captureScreenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) return;
  await tester.pump();
  final boundary =
      screenshotKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('../screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) return;
    final font = FontLoader('ScreenshotFont')
      ..addFont(
        File(
          '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/arial.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await font.load();
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await icons.load();
  });

  Future<FakeAiService> openChat(WidgetTester tester) async {
    if (const bool.fromEnvironment('CAPTURE_SCREENSHOTS')) {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    final service = FakeAiService();
    addTearDown(service.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiServiceProvider.overrideWithValue(service)],
        child: RepaintBoundary(
          key: screenshotKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: const bool.fromEnvironment('CAPTURE_SCREENSHOTS')
                  ? 'ScreenshotFont'
                  : null,
            ),
            home: const ChatScreen(),
          ),
        ),
      ),
    );
    return service;
  }

  testWidgets(
    'Streaming tampil bertahap dan kirim dinonaktifkan saat loading',
    (tester) async {
      final service = await openChat(tester);
      await tester.enterText(find.byType(TextField), 'Pengumuman?');
      await tester.tap(find.byTooltip('Kirim'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
            .onPressed,
        isNull,
      );
      service.responses.add('Buka ');
      await tester.pump();
      expect(find.text('Buka '), findsOneWidget);
      service.responses.add('pengumuman.');
      await tester.pump();
      expect(find.text('Buka pengumuman.'), findsOneWidget);
      await captureScreenshot(tester, 'chat_streaming');
      unawaited(service.responses.close());
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets('API gagal menyediakan tombol coba lagi dan FAQ offline', (
    tester,
  ) async {
    final service = await openChat(tester);
    await tester.enterText(find.byType(TextField), 'Notifikasi?');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pump();
    service.responses.addError(const AiException('Layanan AI sedang sibuk.'));
    unawaited(service.responses.close());
    await tester.pumpAndSettle();
    expect(find.text('Layanan AI sedang sibuk.'), findsNWidgets(2));
    expect(find.text('Coba lagi'), findsOneWidget);
    await captureScreenshot(tester, 'chat_error');
    await tester.tap(find.text('Gunakan FAQ offline'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('FAQ offline: Aktifkan izin notifikasi'),
      findsOneWidget,
    );
    expect(service.calls, 1);
    expect(find.text('Layanan AI sedang sibuk.'), findsOneWidget);
    await captureScreenshot(tester, 'chat_offline');
  });

  testWidgets('Mode offline tidak memanggil AI', (tester) async {
    final service = await openChat(tester);
    await tester.tap(find.byType(Switch));
    await tester.enterText(find.byType(TextField), 'Beasiswa?');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('FAQ offline: Informasi beasiswa'),
      findsOneWidget,
    );
    expect(service.calls, 0);
    unawaited(service.responses.close());
    await tester.pump();
  });

  testWidgets('Data sensitif tidak diteruskan ke service', (tester) async {
    final service = await openChat(tester);
    await tester.enterText(find.byType(TextField), 'NIK 1234567890123456');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hapus nomor identitas'), findsOneWidget);
    expect(service.calls, 0);
    unawaited(service.responses.close());
    await tester.pump();
  });
}
