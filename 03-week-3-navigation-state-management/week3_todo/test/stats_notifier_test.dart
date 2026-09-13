import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/stats_provider.dart';

// ──────────────────────────────────────────────────────────────────────
// _FixedRandom adalah implementasi Random yang selalu mengembalikan
// nilai tetap dari nextDouble(). Ini membuat perilaku acak 30%
// menjadi deterministik sehingga test bisa konsisten dan repeatable.
// ──────────────────────────────────────────────────────────────────────
class _FixedRandom implements Random {
  _FixedRandom(this._value);

  final double _value;

  // Hanya nextDouble() yang diperlukan oleh StatsNotifier.
  @override
  double nextDouble() => _value;

  // Method-method berikut tidak dipakai tapi harus diimplementasi
  // karena merupakan bagian dari interface Random.
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

void main() {
  // ────────────────────────────────────────────────────────────────────
  // Setiap test membuat ProviderContainer baru agar state terisolasi.
  // ProviderContainer memungkinkan kita menguji provider tanpa widget.
  // ────────────────────────────────────────────────────────────────────

  group('StatsNotifier', () {
    // ──────────────────────────────────────────────────────────────────
    // TEST 1: Verifikasi bahwa state awal provider adalah AsyncLoading.
    // Saat provider pertama kali dibaca, build() dipanggil secara
    // asinkron, jadi state langsung adalah loading.
    // ──────────────────────────────────────────────────────────────────
    test('state awal adalah AsyncLoading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Membaca provider memicu build(), tapi karena async,
      // state saat ini masih loading.
      final state = container.read(statsProvider);

      expect(state, isA<AsyncLoading<List<Stat>>>());
    });

    // ──────────────────────────────────────────────────────────────────
    // TEST 2: Ketika Random menghasilkan >= 0.3 (tidak gagal),
    // build() harus mengembalikan AsyncData berisi 3 item Stat.
    // ──────────────────────────────────────────────────────────────────
    test('build() mengembalikan 3 stat saat berhasil (random >= 0.3)',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Baca provider untuk memicu build().
      container.read(statsProvider);

      // Override Random agar selalu "berhasil" (0.5 >= 0.3).
      container.read(statsProvider.notifier).setRandom(_FixedRandom(0.5));

      // Invalidate agar build() dijalankan ulang dengan Random baru.
      container.invalidate(statsProvider);

      // Tunggu semua microtask dan timer selesai (termasuk delay 2 detik
      // yang dalam test berjalan instan karena fake async environment
      // TIDAK digunakan di sini — kita pakai real await).
      // Karena delay real 2 detik, kita perlu menunggu cukup lama.
      // Alternatif: gunakan fakeAsync. Di sini kita pakai loop polling
      // sederhana agar test tetap mudah dipahami.
      await _waitForData(container);

      final state = container.read(statsProvider);

      // Pastikan state adalah AsyncData.
      expect(state, isA<AsyncData<List<Stat>>>());

      // Pastikan ada tepat 3 item.
      final stats = state.value!;
      expect(stats.length, 3);

      // Pastikan label sesuai.
      expect(stats[0].label, 'Pengguna Aktif');
      expect(stats[1].label, 'Tugas Selesai');
      expect(stats[2].label, 'Rata-rata Harian');

      // Pastikan nilai sesuai.
      expect(stats[0].value, 1200);
      expect(stats[1].value, 340);
      expect(stats[2].value, 57);
    });

    // ──────────────────────────────────────────────────────────────────
    // TEST 3: Ketika Random menghasilkan < 0.3 (gagal),
    // refresh() harus menghasilkan AsyncError.
    // Menggunakan refresh() karena invalidate() menghasilkan
    // AsyncLoading yang membungkus error sebelumnya (retrying state).
    // ──────────────────────────────────────────────────────────────────
    test('refresh() menghasilkan AsyncError saat gagal (random < 0.3)',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger build() awal, set Random berhasil agar build() selesai.
      container.read(statsProvider);
      container.read(statsProvider.notifier).setRandom(_FixedRandom(0.5));
      container.invalidate(statsProvider);
      await _waitForData(container);

      // Sekarang ganti Random agar gagal (0.1 < 0.3).
      container.read(statsProvider.notifier).setRandom(_FixedRandom(0.1));

      // Panggil refresh() — ini secara eksplisit set state ke
      // AsyncLoading lalu AsyncValue.guard menangkap exception
      // dan mengubahnya jadi AsyncError.
      await container.read(statsProvider.notifier).refresh();

      final state = container.read(statsProvider);

      // State harus berupa AsyncError.
      expect(state, isA<AsyncError<List<Stat>>>());

      // Pastikan error berisi pesan yang sesuai.
      expect(state.error.toString(), contains('Gagal mengambil data statistik'));
    });

    // ──────────────────────────────────────────────────────────────────
    // TEST 4: Memanggil refresh() harus mengembalikan state ke
    // AsyncLoading lalu ke AsyncData (jika berhasil).
    // ──────────────────────────────────────────────────────────────────
    test('refresh() memperbarui state dari loading ke data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Baca sekali untuk trigger build().
      container.read(statsProvider);

      // Pastikan Random selalu berhasil.
      container.read(statsProvider.notifier).setRandom(_FixedRandom(0.5));

      // Invalidate agar build() pertama berjalan dengan Random baru.
      container.invalidate(statsProvider);
      await _waitForData(container);

      // Sekarang refresh().
      final refreshFuture = container.read(statsProvider.notifier).refresh();

      // Segera setelah memanggil refresh(), state harus loading.
      expect(container.read(statsProvider), isA<AsyncLoading<List<Stat>>>());

      // Tunggu refresh selesai.
      await refreshFuture;

      // State harus kembali ke data.
      final state = container.read(statsProvider);
      expect(state, isA<AsyncData<List<Stat>>>());
      expect(state.value!.length, 3);
    });

    // ──────────────────────────────────────────────────────────────────
    // TEST 5: Memverifikasi equality operator pada model Stat.
    // ──────────────────────────────────────────────────────────────────
    test('Stat equality bekerja dengan benar', () {
      const a = Stat(label: 'Test', value: 42);
      const b = Stat(label: 'Test', value: 42);
      const c = Stat(label: 'Lain', value: 99);

      expect(a, equals(b)); // label & value sama → equal
      expect(a, isNot(equals(c))); // berbeda → not equal
      expect(a.hashCode, b.hashCode); // hash konsisten
      expect(a.toString(), 'Stat(Test, 42)');
    });
  });
}

// ──────────────────────────────────────────────────────────────────────
// Helper: menunggu sampai state menjadi AsyncData.
// ──────────────────────────────────────────────────────────────────────
Future<void> _waitForData(ProviderContainer container) async {
  final stopwatch = Stopwatch()..start();
  while (container.read(statsProvider) is! AsyncData && stopwatch.elapsed.inSeconds < 5) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

