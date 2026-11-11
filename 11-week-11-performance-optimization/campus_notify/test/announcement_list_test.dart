import 'package:campus_notify/features/announcements/presentation/pages/announcement_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Daftar dimuat bertahap, detail dan refresh tetap berjalan', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AnnouncementListPage()));
    expect(find.byType(AnnouncementTile).evaluate().length, lessThan(120));
    expect(find.text('Jadwal kuliah 1'), findsOneWidget);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(
      find.text('Contoh informasi untuk Jadwal kuliah 1.'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Pembaruan: 1'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Seminar kampus 120'), 500);
    expect(find.text('Seminar kampus 120'), findsOneWidget);
  });
}
