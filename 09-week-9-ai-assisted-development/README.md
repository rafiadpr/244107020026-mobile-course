# Praktikum 1: Prompt dan context engineering

1. Formula 5 slot

```
Peran:
Kamu adalah senior Flutter developer yang memahami Clean Architecture,
Riverpod, dan pengujian Flutter.

Konteks:
Saya mengerjakan praktikum Week 9 menggunakan Campus Notify hasil Week 7.
Instruksi search judul notes saya adaptasi menjadi search judul pengumuman.

Proyek sudah memiliki layer data, domain, dan presentation.
Halaman pengumuman saat ini menampilkan detail contoh berdasarkan ID.
Daftar pengumuman belum tersedia.
AnnouncementRepository yang ada menangani FCM dan registrasi perangkat,
bukan pengambilan daftar pengumuman.

Saya lampirkan struktur folder, dependencies, kontrak repository,
provider, halaman, dan rute yang relevan di bawah.

Tugas:
Tambahkan satu fitur kecil berupa pencarian judul pengumuman.
Gunakan daftar data contoh lokal dan tampilkan empty state jika tidak cocok.
Hubungkan daftar dengan navigasi yang diperlukan.

Kriteria keberhasilan:
1. Query kosong menampilkan seluruh data.
2. Pencarian berdasarkan judul dan tidak membedakan huruf besar/kecil.
3. Spasi awal dan akhir query diabaikan.
4. Query tidak cocok menampilkan "Pengumuman tidak ditemukan".
5. Menghapus query memulihkan seluruh daftar.
6. Daftar sumber tidak berubah akibat pencarian.

Batas:
- Pertahankan Clean Architecture dan pola Riverpod proyek.
- Domain berupa Dart murni, tanpa Flutter/Riverpod/Dio/SQLite.
- Aturan pencarian berada di use case domain.
- Widget menangani tampilan dan input.
- Notifier mengelola state.
- Pisahkan kontrak daftar pengumuman dari repository FCM.
- Jangan mengubah auth, alur FCM, atau konfigurasi Firebase.
- Jangan menambah package atau backend.
- Hindari fungsi panjang; pecah berdasarkan tanggung jawab.
- Jangan mengasumsikan method atau endpoint yang belum tersedia.

Output:
1. Asumsi dan daftar file yang ditambah/diubah.
2. Kode per file.
3. Unit test untuk perilaku pencarian.
4. Satu widget test untuk empty state.
5. Cara menjalankan dan menguji.
6. Penjelasan alur data dan tanggung jawab setiap layer.
```

2. Buruk vs baik

Contoh prompt buruk:

> Buatkan fitur search pengumuman yang bagus.

Prompt tersebut tidak menjelaskan sumber data, aturan pencarian, batas arsitektur, atau hasil yang diharapkan.

Prompt pada nomor 1 diperjelas dengan konteks Campus Notify, sumber data contoh lokal, aturan pencarian case-insensitive, empty state, batas perubahan, serta kebutuhan pengujian. Dengan demikian, hasil AI memiliki kriteria yang dapat diverifikasi.

3. Beri konteks, bukan secret

Konteks yang akan disertakan:
- Struktur folder fitur announcements.
- Bagian SDK dan dependencies dari pubspec.yaml.
- Kontrak AnnouncementRepository yang saat ini menangani FCM.
- Kode halaman pengumuman, provider, dan rute yang relevan.

Batas perubahan:
- Auth, alur FCM, dan konfigurasi Firebase tidak diubah.
- Implementasi mengikuti pembagian data, domain, dan presentation.

Token FCM, JWT, password, dan kredensial privat tidak disertakan. Jika diperlukan dalam potongan kode, nilainya diganti placeholder.


# Praktikum 2: Generate dan verifikasi search

1. Generate satu fitur kecil

Output awal di [ai-output-awal.md](docs/ai-output-awal.md)

2. Verifikasi 6 langkah

| No. | Langkah verifikasi | Hasil | Status |
| --- | --- | --- | --- |
| 1 | Baca setiap baris kode | Alur pencarian dipisahkan menjadi repository, use case, notifier, dan widget. Normalisasi query dilakukan di use case. | Sesuai |
| 2 | Cek import | File domain baru tidak mengimpor Flutter, Dio, SQLite, atau Riverpod. | Lulus |
| 3 | Cek API | Method yang digunakan tersedia pada Dart, package terpasang, atau kontrak repository baru. Tidak ditemukan method fiktif. | Lulus |
| 4 | Jalankan `flutter analyze` | Hasil `No issues found!`. | Lulus |
| 5 | Test search sukses dan tidak cocok | 9 unit test search, 1 test notifier, dan 1 widget test lulus. Total seluruh suite: 54 test lulus. | Lulus |
| 6 | Uji manual query kosong, cocok, dan tidak cocok | Pengujian langsung pada aplikasi beserta screenshot belum dilakukan. | Belum dilakukan |

Verifikasi otomatis dilakukan pada proyek. Setelah kode diterapkan pada proyek utama, analyzer dan test perlu dijalankan kembali. Belum ditemukan bug/halusinasi yang dapat dibuktikan, sehingga bukti wajib temuan masih perlu dilengkapi.

3. Contoh test bukti
![Test Bukti](screenshots/tes_sebelum_perbaikan.png)
query dengan spasi di tepi ikut dicocokkan. test tersebut seharusnya gagal karena hasil aktual [], sedangkan hasil yang diharapkan ['43'].


# Praktikum 3: Debug dan refactor

1. Debug dengan test merah

```
Lanjutkan Praktikum 3: Debug dan refactor pada proyek
09-week-9-ai-assisted-development/campus_notify.

Kasus debugging:
Pada versi kode dalam screenshot, normalisasi query hanya menggunakan:

final normalizedQuery = query.toLowerCase();

Pencarian dengan query '  beasiswa  ' menghasilkan [],
padahal hasil yang diharapkan adalah pengumuman dengan ID '43'.
Query yang hanya berisi spasi juga seharusnya menampilkan seluruh data.

Bukti:
Saya lampirkan screenshot kode dan output test gagal.
Test terkait berada pada test/search_announcements_test.dart.

Periksa juga kondisi file saat ini. Jika trim() sudah tersedia,
jelaskan bahwa kode saat ini sudah mengandung perbaikan.
Jangan menghapus perbaikan atau membuat ulang bug.

Tugas:
1. Jelaskan reproduksi dan akar masalah berdasarkan bukti.
2. Bandingkan kondisi sebelum dan sesudah perbaikan.
3. Pertahankan test pembukti dan seluruh ekspektasinya.
4. Periksa pembagian tanggung jawab:
   - widget: tampilan dan input;
   - notifier: state;
   - use case domain: normalisasi dan filter;
   - repository: sumber data.
5. Refactor hanya jika ditemukan masalah nyata.
   Jangan membuat perubahan tambahan hanya untuk memenuhi bagian refactor.
6. Periksa fungsi di atas 40 baris pada fitur ini dan pecah jika
   memiliki beberapa tanggung jawab.
7. Jalankan:
   flutter test test/search_announcements_test.dart
   flutter analyze
   dart format --set-exit-if-changed .
   flutter test

Batas:
Jangan mengubah auth, FCM, Firebase, dependencies, atau ekspektasi test.
Jika format belum sesuai, rapikan lalu ulangi pemeriksaan.
Jangan mengisi README, AI log, AI Challenge, atau refleksi.

Output:
Ringkasan akar masalah, perubahan yang benar-benar dilakukan,
hasil pemeriksaan arsitektur, dan hasil aktual setiap perintah.
Bedakan hasil yang sudah dijalankan dari langkah yang belum dilakukan.
```

Kasus debugging berfokus pada normalisasi query pencarian. Pada versi sebelum perbaikan, query hanya diubah menjadi huruf kecil tanpa menghapus spasi awal dan akhir.

| Aspek | Hasil pemeriksaan |
| --- | --- |
| Input pemicu | `'  beasiswa  '` |
| Hasil yang diharapkan | Pengumuman dengan ID `'43'` |
| Hasil aktual sebelum perbaikan | Daftar kosong `[]` |
| Akar masalah | Spasi query ikut diperiksa oleh `contains()` |
| Perbaikan | Menggunakan `query.trim().toLowerCase()` |
| Test pembukti | `Spasi awal dan akhir query diabaikan` |

Output AI di [docs/ai-output-praktikum3.md](docs/ai-output-praktikum3.md)

2. Refactor ke layer yang benar

Tidak ada yang perlu direfactor.

3. Verifikasi akhir

| Pemeriksaan | Hasil |
| --- | --- |
| Unit test pencarian | ![Test Pencarian](screenshots/search_awal.jpg) |
| `flutter analyze` | ![Test Akhir](screenshots/analyze_hasil_perbaikan.png) |
| Pemeriksaan format | Berhasil |
| Seluruh test | ![Test Akhir](screenshots/tes_hasil_perbaikan.png) |

# AI Challenge


## AI Prompt Challenge


## AI Verification Checklist


### Tanggung jawab teknis (pada folder docs/):

1. simpan prompt

2. output AI

3. tabel usulan-vs-keputusan

4. bukti analyze + test


# Refactoring, testing, dan error umum

## Refactoring Challenge

1. Perkecil hasil AI di atas 80 baris menjadi fungsi/use case kecil yang bisa diuji.

2. Pindahkan filter/search dari widget ke use case domain yang murni.

3. Hapus import lintas layer dan pastikan analyze tetap bersih.


## Testing

## Checklist verifikasi mandiri


# Tugas, refleksi, dan referensi

## Refleksi

1. Satu halusinasi AI apa yang Anda temukan dan bagaimana membuktikannya?

2. Prompt mana yang paling membantu dan apa yang Anda ubah?

3. Satu refactor apa yang Anda lakukan pada kode AI?

4. Keputusan terima/tolak mana yang paling sulit?

