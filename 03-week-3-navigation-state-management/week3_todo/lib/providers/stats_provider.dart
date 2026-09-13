import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ──────────────────────────────────────────────────────────────────────
// Model sederhana yang merepresentasikan satu baris statistik.
// Memisahkan data ke dalam model sendiri membuat kode lebih mudah
// diuji dan di-maintain dibanding memakai Map atau tuple.
// ──────────────────────────────────────────────────────────────────────
class Stat {
  const Stat({required this.label, required this.value});

  /// Nama metrik, contoh: "Pengguna Aktif"
  final String label;

  /// Nilai metrik, contoh: 1200
  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stat && label == other.label && value == other.value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'Stat($label, $value)';
}

// ──────────────────────────────────────────────────────────────────────
// AsyncNotifier mengelola state asinkron secara deklaratif.
// State yang diekspos bertipe AsyncValue<List<Stat>>, yang secara
// otomatis memodelkan tiga kondisi: loading, error, dan data.
// ──────────────────────────────────────────────────────────────────────
class StatsNotifier extends AsyncNotifier<List<Stat>> {
  // Random generator disimpan sebagai field agar bisa di-override
  // saat testing (dependency injection sederhana).
  Random _random = Random();

  /// Mengganti Random instance — berguna untuk unit test agar
  /// perilaku acak menjadi deterministik.
  void setRandom(Random random) => _random = random;

  // ────────────────────────────────────────────────────────────────────
  // build() dipanggil otomatis saat provider pertama kali dibaca
  // atau setelah ref.invalidate(). Return value-nya menjadi state
  // awal (AsyncData). Selama menunggu Future, state = AsyncLoading.
  // ────────────────────────────────────────────────────────────────────
  @override
  Future<List<Stat>> build() async {
    return _fetchStats();
  }

  // ────────────────────────────────────────────────────────────────────
  // Method publik untuk memicu refresh manual dari UI.
  // 1. Set state ke AsyncLoading agar UI menampilkan spinner.
  // 2. AsyncValue.guard menjalankan future dan otomatis menangkap
  //    exception, mengubahnya jadi AsyncError — tidak perlu try/catch.
  // ────────────────────────────────────────────────────────────────────
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchStats());
  }

  // ────────────────────────────────────────────────────────────────────
  // Simulasi pemanggilan API:
  //  • Delay 2 detik meniru latensi jaringan.
  //  • 30% kemungkinan melempar exception (simulasi kegagalan).
  //  • Jika berhasil, mengembalikan 3 item statistik.
  // ────────────────────────────────────────────────────────────────────
  Future<List<Stat>> _fetchStats() async {
    await Future.delayed(const Duration(seconds: 2));

    // _random.nextDouble() menghasilkan 0.0 – 1.0;
    // jika < 0.3 (30%), anggap gagal.
    if (_random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik dari server');
    }

    // Data dummy yang dikembalikan jika berhasil.
    return const [
      Stat(label: 'Pengguna Aktif', value: 1200),
      Stat(label: 'Tugas Selesai', value: 340),
      Stat(label: 'Rata-rata Harian', value: 57),
    ];
  }
}

// ──────────────────────────────────────────────────────────────────────
// Provider global yang bisa di-watch dari widget mana saja.
// AsyncNotifierProvider otomatis mengurus lifecycle: membuat instance
// StatsNotifier, memanggil build(), dan membersihkan saat tidak
// ada lagi listener.
// ──────────────────────────────────────────────────────────────────────
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<Stat>>(StatsNotifier.new);
