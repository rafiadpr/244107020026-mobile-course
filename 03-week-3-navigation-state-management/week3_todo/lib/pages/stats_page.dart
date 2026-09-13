import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

// ──────────────────────────────────────────────────────────────────────
// StatsPage adalah ConsumerWidget sehingga bisa mengakses WidgetRef
// untuk membaca provider Riverpod. ConsumerWidget lebih ringan
// dibanding ConsumerStatefulWidget karena tidak butuh State object.
// ──────────────────────────────────────────────────────────────────────
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ──────────────────────────────────────────────────────────────────
    // ref.watch membuat widget rebuild setiap kali state berubah.
    // statsAsync bertipe AsyncValue<List<Stat>>, bukan List<Stat>,
    // sehingga kita harus "membuka" nilainya dengan .when().
    // ──────────────────────────────────────────────────────────────────
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        actions: [
          // ────────────────────────────────────────────────────────────
          // Tombol refresh di AppBar memanggil notifier.refresh().
          // ref.read (bukan ref.watch) dipakai di callback karena
          // kita hanya butuh akses sekali, tidak perlu subscribe.
          // ────────────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: () => ref.read(statsProvider.notifier).refresh(),
          ),
        ],
      ),
      // ────────────────────────────────────────────────────────────────
      // AsyncValue.when melakukan pattern matching terhadap tiga
      // kondisi: loading, error, dan data. Ini menggantikan
      // boilerplate if/else atau FutureBuilder secara elegan.
      // ────────────────────────────────────────────────────────────────
      body: statsAsync.when(
        // ─── STATE: LOADING ──────────────────────────────────────────
        // Ditampilkan saat build() atau refresh() sedang berjalan.
        // Spinner di tengah layar memberi feedback visual ke pengguna.
        // ─────────────────────────────────────────────────────────────
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat statistik...'),
            ],
          ),
        ),

        // ─── STATE: ERROR ────────────────────────────────────────────
        // Ditampilkan ketika _fetchStats() melempar exception.
        // Menampilkan pesan error dan tombol retry.
        // ref.invalidate membuat provider di-build() ulang dari nol,
        // menghapus error lama dan kembali ke AsyncLoading.
        // ─────────────────────────────────────────────────────────────
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikon error besar agar mudah terlihat.
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat: $err',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                // Tombol retry: invalidate menghapus cache provider
                // dan memicu pemanggilan build() kembali.
                FilledButton.icon(
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.replay),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),

        // ─── STATE: DATA (SUCCESS) ──────────────────────────────────
        // Ditampilkan ketika Future selesai tanpa error.
        // `stats` sudah bertipe List<Stat>, tinggal dirender.
        // ─────────────────────────────────────────────────────────────
        data: (stats) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: stats.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return ListTile(
              // Ikon lingkaran berisi nomor urut.
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(stat.label),
              // Nilai ditampilkan di sebelah kanan.
              trailing: Text(
                '${stat.value}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          },
        ),
      ),
    );
  }
}
