# Verifikasi praktikum

Pemeriksaan dijalankan pada salinan Campus Notify pertemuan 11.

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub` | 44 test lulus |
| Widget test daftar | Item dimuat bertahap, detail dapat dibuka dan ditutup, refresh memperbarui penghitung, serta item terakhir dapat dicapai |
| Integration test `profile` | Versi sebelum dan sesudah optimasi menyelesaikan skenario yang sama |

Test bawaan login, repository, notifikasi, formatter, dan halaman lama ikut dijalankan. Smoke test menampilkan pesan bahwa Firebase belum diinisialisasi pada lingkungan test. Pesan tersebut ditangani oleh service dan seluruh test tetap lulus.

## Menjalankan aplikasi

```bash
cd 11-week-11-performance-optimization/campus_notify
flutter pub get
flutter run
```

Setelah login, pilih `Buka Daftar Pengumuman`. Daftar berisi data contoh lokal. Tekan salah satu item untuk membuka detail, lalu kembali melalui tombol pada AppBar. Tarik daftar ke bawah untuk memperbarui penghitung. Jeda 300 ms merupakan simulasi pemuatan lokal.

## Mengulang profiling

Jalankan dari folder `campus_notify` melalui PowerShell:

```powershell
.\tool\profile.ps1 -Stage before
.\tool\profile.ps1 -Stage after
```

Script menyiapkan runner Windows di `.profile_runner`, menyalin versi halaman yang dipilih, dan menjalankan integration test dalam mode `profile`. Versi `before` berasal dari snapshot pada `docs/baseline`, sedangkan versi `after` memakai kode halaman saat ini. Kode aplikasi utama tidak ditimpa.

Rekaman frame, timeline, allocation profile, serta heap snapshot ditulis ke `docs/profiling`. Folder ini disimpan lokal dan diabaikan oleh Git. Ukuran heap menggunakan byte; durasi frame mentah menggunakan mikrodetik. Rekaman biner `.bin.gz` berisi heap snapshot Dart yang dikompresi dengan gzip.
