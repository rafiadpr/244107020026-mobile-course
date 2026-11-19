import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:testing_lab/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pengguna dapat menambahkan tugas dan melihatnya di daftar', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    final titleField = find.byKey(const Key('task-title-field'));
    final saveButton = find.byKey(const Key('save-task-button'));

    expect(find.text('Daftar tugas'), findsOneWidget);
    expect(titleField, findsOneWidget);
    expect(find.byType(ListTile), findsNothing);

    await tester.enterText(titleField, '   ');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Judul tugas wajib diisi.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);

    await tester.enterText(titleField, '  Baca materi  ');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Baca materi'), findsOneWidget);
    expect(tester.widget<TextFormField>(titleField).controller!.text, isEmpty);
    expect(find.text('Judul tugas wajib diisi.'), findsNothing);

    await tester.enterText(titleField, 'Kerjakan latihan');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Baca materi'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Kerjakan latihan'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(tester.widget<TextFormField>(titleField).controller!.text, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 45)));
}
