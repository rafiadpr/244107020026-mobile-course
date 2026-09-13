import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart';
import 'package:week3_todo/providers/stats_provider.dart';

// ──────────────────────────────────────────────────────────────────────
// Notifier pengganti untuk testing: langsung return data tanpa delay
// dan tanpa random failure. Ini menghilangkan timer sehingga
// widget test tidak konflik dengan FakeAsync.
// ──────────────────────────────────────────────────────────────────────
class _ImmediateStatsNotifier extends StatsNotifier {
  @override
  Future<List<Stat>> build() async {
    // Tidak ada Future.delayed — langsung return data.
    return const [
      Stat(label: 'Pengguna Aktif', value: 1200),
      Stat(label: 'Tugas Selesai', value: 340),
      Stat(label: 'Rata-rata Harian', value: 57),
    ];
  }
}

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsProvider.overrideWith(() => _ImmediateStatsNotifier()),
        ],
        child: const MyApp(),
      ),
    );
    
    await tester.pumpAndSettle();

    expect(find.text('Belum ada tugas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    
    await tester.tap(find.text('Tambah'));
    await tester.pump();

    expect(find.widgetWithText(ListTile, 'Kerjakan PR minggu 3'), findsOneWidget);
  });
}

