// Widget test untuk memverifikasi bahwa StatsPage menampilkan
// judul "Statistik", loading state, lalu data setelah resolve.
//
// Menggunakan provider override agar build() tidak punya
// Future.delayed (timer) — menghindari "Timer is still pending"
// yang terjadi di FakeAsync environment milik flutter_test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/pages/stats_page.dart';
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
  testWidgets('StatsPage menampilkan judul lalu data setelah loading',
      (WidgetTester tester) async {
    // Override statsProvider agar memakai notifier tanpa delay.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsProvider.overrideWith(() => _ImmediateStatsNotifier()),
        ],
        child: const MaterialApp(home: StatsPage()),
      ),
    );

    // Judul AppBar harus langsung tampil.
    expect(find.text('Statistik'), findsOneWidget);

    // Pada frame pertama, state masih AsyncLoading karena
    // build() async belum resolve (walaupun tanpa delay,
    // Future tetap resolve di microtask berikutnya).
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump agar microtask dari build() async selesai.
    await tester.pumpAndSettle();

    // Sekarang state sudah AsyncData — data tampil di ListView.
    expect(find.text('Pengguna Aktif'), findsOneWidget);
    expect(find.text('Tugas Selesai'), findsOneWidget);
    expect(find.text('Rata-rata Harian'), findsOneWidget);

    // Nilai juga ditampilkan.
    expect(find.text('1200'), findsOneWidget);
    expect(find.text('340'), findsOneWidget);
    expect(find.text('57'), findsOneWidget);
  });
}
