# Praktikum 3
1. Ubah build() sementara untuk melempar error: throw Exception('Gagal terhubung ke server');. Jalankan dan amati UI error beserta tombol Coba lagi.

2. Refleksikan: mengapa menampilkan ulang data lama (stale data) dengan indikator refresh kadang lebih baik daripada mengosongkan layar? Kapan pola itu penting?
Menampilkan data lama dan indikator refresh lebih baik daripada mengosongkan layar karena user tetap bisa melihat dan berinteraksi dengan konten yang ada, jika layar dikosongkan akan memberikan kesan aplikasi "rusak". Menurut saya pola ini penting di infinite scroll / pagination (situasi data lama masih relevan saat menunggu data baru)


# AI Verification Checklist
## 1. Prompt yang Digunakan
Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.

## 2. Output Awal AI
AI menghasilkan tiga file:
- `lib/providers/stats_provider.dart` — model `Stat` + `StatsNotifier`
- `lib/pages/stats_page.dart` — UI `ConsumerWidget`
- `test/stats_notifier_test.dart` — 5 unit test

Sebelum kode AI diterima, verifikasi hal berikut dan catat temuan Anda di README:

1. Apakah state diubah secara immutable (tidak ada state.add() atau mutasi list langsung)?
- Iya, state diubah secara immutable. Tidak ada penggunaan state.add() atau mutasi langsung

2. Apakah ref.watch hanya dipakai di dalam build, dan ref.read di callback?
- Iya, ref.watch hanya diletakkan di dalam fungsi build untuk memantau perubahan data. Sedangkan ref.read hanya digunakan di dalam callback tombol

3. Apakah ketiga state AsyncValue benar-benar ditangani (bukan hanya success)?
- Iya, ketiga state sudah ditangani menggunakan metode .when(). Kode sudah menyediakan tampilan untuk kondisi loading, error, dan data sukses

4. Apakah provider dideklarasikan dengan tipe eksplisit dan tidak duplikat dengan provider lain?
- Iya, tipe data pada provider ditulis menggunakan AsyncNotifierProvider<StatsNotifier, List<Stat>> dan tidak ada duplikasi provider

5. Apakah kode AI memakai API Riverpod versi lama (StateProvider antipattern, StateNotifierProvider usang, atau Consumer bertingkat yang tidak perlu)? Perbaiki ke pola Notifier/ConsumerWidget.
- Tidak, kode AI sudah menggunakan API Riverpod versi terbaru (kode sudah pakai AsyncNotifier dan ConsumerWidget)

6. Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?
- Lolos untuk flutter analyze, tapi hasil awal dari flutter test sempat gagal.

## 3. Perbaikan Hasil AI
- Kesalahan pada kode awal:
Saat menjalankan flutter test, tes ke-3 (skenario saat data gagal diambil) error. Penyebabnya adalah AI menggunakan invalidate() untuk tes kondisi error. Pada Riverpod, kode ini justru membuat status berubah menjadi AsyncLoading, bukan menghasilkan AsyncError.

- Perbaikan yang dilakukan:
Kode invalidate() pada file stats_notifier_test.dart telah diganti dengan memanggil fungsi refresh(). Setelah perbaikan, seluruh tes sudah berhasil.


# Refactoring dan testing
## 1. Refactoring Challenge
Lakukan refactoring berikut pada aplikasi ToDo Anda, lalu commit dengan pesan yang jelas:

1. Pisahkan widget bar ToDo menjadi TodoTile tersendiri agar build lebih pendek dan mudah diuji.
- Pemisahan UI untuk satu item tugas telah dilakukan dengan membuat widget `TodoTile` pada file [`lib/widgets/todo_tile.dart`](lib/widgets/todo_tile.dart).
2. Ekstrak logika filter (misal tampilkan hanya yang belum selesai) menjadi Provider turunan yang membaca todoListProvider.
- Logika filter telah dipisahkan dengan membuat `incompleteTodosProvider` pada [`lib/providers/todo_provider.dart`](lib/providers/todo_provider.dart).
3. Integrasikan aplikasi ToDo dengan GoRouter: / untuk daftar dan /stats untuk halaman statistik, tambahkan NavigationBar untuk berpindah.
- Aplikasi telah diubah untuk menggunakan `go_router` pada [`lib/main.dart`](lib/main.dart) menggantikan navigasi bawaan.

## 2. Testing
Widget test untuk memastikan UI bereaksi terhadap perubahan state provider. Jalankan seluruh verifikasi:
- Kode pengujian (widget test) untuk skenario "menambah tugas baru" telah ditambahkan dan disesuaikan di [`test/widget_test.dart`](test/widget_test.dart).
![Flutter Test](week3_todo/screenshots/flutter_test.png)

## 3. Checklist verifikasi mandiri
1. Navigasi GoRouter bekerja: pindah halaman, back, dan akses path detail langsung.
![Navigasi](week3_todo/screenshots/tampilan_awal_refactoring.jpg)
2. ProviderScope membungkus root aplikasi; state ToDo bertahan saat berpindah halaman.
![Final Page](week3_todo/screenshots/tampilan_final_refactor.jpg)
3. UI AsyncValue menangani loading, error, dan success, bukan hanya success.
![Error Page](week3_todo/screenshots/page_error.jpg)
4. flutter analyze tanpa issue dan semua test lulus.
![Flutter Analyze](week3_todo/screenshots/flutter_analyze.png)
5. Hasil AI diverifikasi dan didokumentasikan pada folder docs/.