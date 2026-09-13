# Refactoring dan testing

## 1. Refactoring Challenge
Lakukan refactoring berikut pada aplikasi ToDo Anda, lalu commit dengan pesan yang jelas:

1. **Pisahkan widget bar ToDo menjadi TodoTile tersendiri agar build lebih pendek dan mudah diuji.**
   - **Jawaban**: Pemisahan UI untuk satu item tugas telah dilakukan dengan membuat widget `TodoTile` pada file [`lib/widgets/todo_tile.dart`](lib/widgets/todo_tile.dart). Widget ini adalah `ConsumerWidget` yang menerima data `Todo` dan indeks aslinya, serta langsung menangani interaksi (*toggle* dan *delete*) menggunakan `ref.read`. Pada [`lib/pages/todo_page.dart`](lib/pages/todo_page.dart), `ListView.builder` sekarang menjadi jauh lebih bersih karena hanya memanggil `TodoTile`.

2. **Ekstrak logika filter (misal tampilkan hanya yang belum selesai) menjadi Provider turunan yang membaca todoListProvider.**
   - **Jawaban**: Logika filter telah dipisahkan dengan membuat `incompleteTodosProvider` pada [`lib/providers/todo_provider.dart`](lib/providers/todo_provider.dart). Provider turunan ini menggunakan `ref.watch(todoListProvider)` dan memfilter tugas yang memiliki status `done == false`. Halaman ToDo di [`lib/pages/todo_page.dart`](lib/pages/todo_page.dart) kemudian diubah untuk memantau provider turunan ini sehingga hanya tugas yang belum selesai yang dirender.

3. **Integrasikan aplikasi ToDo dengan GoRouter: / untuk daftar dan /stats untuk halaman statistik, tambahkan NavigationBar untuk berpindah.**
   - **Jawaban**: Aplikasi telah diubah untuk menggunakan `go_router` pada [`lib/main.dart`](lib/main.dart) menggantikan navigasi bawaan. Rute dikonfigurasi menggunakan `StatefulShellRoute` agar state halaman tetap terjaga saat berpindah tab. Terdapat dua branch: `/` untuk `TodoPage` dan `/stats` untuk `StatsPage`. Antarmuka tab diimplementasikan dengan `NavigationBar` pada widget `MainLayout` yang terletak di [`lib/widgets/main_layout.dart`](lib/widgets/main_layout.dart).

## 2. Testing
Widget test untuk memastikan UI bereaksi terhadap perubahan state provider. Jalankan seluruh verifikasi:
- **Jawaban**: Kode pengujian (widget test) untuk skenario "menambah tugas baru" telah ditambahkan dan disesuaikan di [`test/widget_test.dart`](test/widget_test.dart). Pengujian ini men-tap tombol tambah, memasukkan teks, dan memverifikasi bahwa `ListTile` dengan teks "Kerjakan PR minggu 3" berhasil muncul di layar. Uji ini berjalan dalam lingkup `ProviderScope` dengan *override* pada `statsProvider` agar terhindar dari bentrok dengan timer *FakeAsync*.

## 3. Checklist verifikasi mandiri
1. **Navigasi GoRouter bekerja: pindah halaman, back, dan akses path detail langsung.**
   - **Jawaban**: Ya. Karena menggunakan `go_router` dengan `StatefulShellRoute`, perpindahan antar halaman menggunakan `NavigationBar` (di bawah layar) terasa instan, dan aplikasi mendukung *deep linking* langsung ke path `/stats` jika dibutuhkan.
2. **ProviderScope membungkus root aplikasi; state ToDo bertahan saat berpindah halaman.**
   - **Jawaban**: Ya. `ProviderScope` membungkus root aplikasi (`MyApp`) pada [`lib/main.dart`](lib/main.dart). Berkat ini serta penggunaan `StatefulShellBranch`, jika pengguna memanipulasi *checkbox* ToDo lalu pindah ke Statistik dan kembali lagi, perubahan tidak hilang dan halaman tidak perlu di-*reload* dari awal.
3. **UI AsyncValue menangani loading, error, dan success, bukan hanya success.**
   - **Jawaban**: Ya. Pada [`lib/pages/stats_page.dart`](lib/pages/stats_page.dart), state asinkron diproses menggunakan `statsAsync.when()`. Ini secara eksplisit mendefinisikan tampilan indikator putar untuk status `loading:`, ikon *error* lengkap dengan pesan kesalahan dan tombol *retry* untuk status `error:`, dan daftar metrik dalam ListView untuk status `data:`.
4. **flutter analyze tanpa issue dan semua test lulus.**
   - **Jawaban**: Ya. Perintah `flutter analyze` berjalan bersih tanpa peringatan atau masalah linting. Perintah `flutter test` lulus sepenuhnya, mencakup ke-5 *unit test* untuk perilaku `AsyncNotifier` dan *widget test* untuk penambahan tugas baru.
5. **Hasil AI diverifikasi dan didokumentasikan pada folder docs/.**
   - **Jawaban**: Ya. Semua proses verifikasi (*prompt*, masalah yang ditemui, hasil pengecekan) telah ditulis secara rapi dan rinci ke dalam dokumen *checklist* pada folder [`docs/ai_verification_checklist.md`](docs/ai_verification_checklist.md).
