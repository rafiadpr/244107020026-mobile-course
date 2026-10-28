## 1. Tujuan dan cakupan
Menambahkan satu fitur kecil berupa pencarian judul pengumuman.

## 2. Kondisi awal proyek
![Kondisi Awal](../screenshots/kondisi_awal.png)

## 3. Prompt awal dan konteks
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

## 4. Output awal AI
Output awal di [ai-output-awal.md](ai-output-awal.md)

## 5. Verifikasi awal
| No. | Langkah verifikasi | Hasil | Status |
| --- | --- | --- | --- |
| 1 | Baca setiap baris kode | Alur pencarian dipisahkan menjadi repository, use case, notifier, dan widget. Normalisasi query dilakukan di use case. | Sesuai |
| 2 | Cek import | File domain baru tidak mengimpor Flutter, Dio, SQLite, atau Riverpod. | Lulus |
| 3 | Cek API | Method yang digunakan tersedia pada Dart, package terpasang, atau kontrak repository baru. Tidak ditemukan method fiktif. | Lulus |
| 4 | Jalankan `flutter analyze` | Hasil `No issues found!`. | Lulus |
| 5 | Test search sukses dan tidak cocok | 9 unit test search, 1 test notifier, dan 1 widget test lulus. Total seluruh suite: 54 test lulus. | Lulus |
| 6 | Uji manual query kosong, cocok, dan tidak cocok | Query kosong menampilkan tiga pengumuman; `tengah` menampilkan jadwal ujian; `zzzz` menampilkan empty state. | Lulus |

| Query kosong | Query cocok | Query tidak cocok |
| --- | --- | --- |
| ![Query kosong](../screenshots/search_awal.jpg) | ![Query cocok](../screenshots/search_success.jpg) | ![Empty state](../screenshots/search_failed.jpg) |

## 6. Bug dan bukti test merah
### Kasus debugging: spasi pada query

Pada versi sebelum perbaikan, normalisasi menggunakan
`query.toLowerCase()`. Query `'  beasiswa  '` menghasilkan daftar
kosong, sedangkan test mengharapkan pengumuman dengan ID `'43'`.

Penyebabnya adalah spasi awal dan akhir belum dibuang sebelum
pencocokan judul. Test yang sudah tersedia menjadi bukti kegagalan
perilaku tersebut.

![Test Bukti](../screenshots/tes_sebelum_perbaikan.png)
![Code Bug](../screenshots/kode_sebelum_perbaikan.png)

## 7. Perbaikan dan refactor
### Prompt debugging
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

### Output
Output awal di [ai-output-praktikum3.md](ai-output-praktikum3.md)

### Perbaikan
Normalisasi query menggunakan `query.trim().toLowerCase()`. Ekspektasi test dipertahankan agar perbaikan mengikuti perilaku yang ditentukan.

### Pemeriksaan arsitektur
Tidak ada arsitektur yang diubah atau refactor.

### Hasil pengujian
![Test Akhir](../screenshots/analyze_hasil_perbaikan.png)
![Test Akhir](../screenshots/tes_hasil_perbaikan.png)

## 8. Prompt dan output review AI

```
Peran:
Senior Flutter developer yang memahami Clean Architecture,
Riverpod, dan pengujian.

Konteks:
- Fitur menggunakan tiga data contoh lokal.
- Search berdasarkan sebagian judul, case-insensitive,
  serta mengabaikan spasi awal/akhir query.
- Query kosong menampilkan seluruh daftar.
- Query tidak cocok menampilkan empty state.
- Menghapus query memulihkan seluruh daftar.
- Kontrak daftar pengumuman terpisah dari kontrak FCM.
- Detail pengumuman masih menggunakan halaman contoh lama.
- Praktikum 3 mempertahankan normalisasi trim().toLowerCase().
- Hasil pemeriksaan terakhir: 9 unit test search dan
  54 test keseluruhan lulus; analyzer bersih.
- Pemeriksaan format lib dan test berhasil.
  Pemeriksaan seluruh direktori terkendala artefak build.

Tugas:
Baca implementasi dan test fitur yang sebenarnya, termasuk perubahan
rute dan halaman yang berhubungan dengan pencarian.

Fokus review:
1. Kebenaran perilaku search dan state.
2. Pembagian tanggung jawab dan arah dependensi.
3. Kecukupan unit test, widget test, dan test navigasi.
4. Lifecycle controller/provider dan pemulihan query saat kembali
   dari detail.

Output:
Berikan sampai tiga temuan konkret.
Untuk setiap temuan, sertakan:
- ID temuan;
- file dan nomor baris;
- kategori: bug, celah test, atau peningkatan opsional;
- tingkat: blocker atau saran;
- pemicu dan dampak;
- bukti dari kode atau test;
- perbaikan terkecil yang disarankan.

Jika tidak ditemukan bug, nyatakan dengan jelas.
Jika relevan, boleh berikan alternatif peningkatan opsional
beserta manfaat dan biayanya.
Jangan membuat temuan untuk memenuhi jumlah.

Batas:
- Tahap ini hanya review; jangan mengubah file.
- Jangan mengubah auth, FCM, Firebase, atau dependencies.
- Jangan menyebut kasus trim sebagai bug baru jika kode saat ini
  sudah benar.
- Jangan menganggap detail contoh sebagai fitur backend yang hilang.
- Abaikan preferensi gaya penulisan.
- Jangan mengisi README atau AI log.
- Bedakan pemeriksaan yang dijalankan dari dugaan yang belum terbukti.
```

Tindak lanjut di [ai-challenge-tindak-lanjut.md](ai-challenge-tindak-lanjut.md)
Output di [ai-review-challenge.md](ai-review-challenge.md)

## 9. Keputusan per temuan

| ID | Temuan | Bukti verifikasi | Keputusan | Alasan teknis |
|---|---|---|---|---|
| AC-01 | Navigasi dan pemulihan query belum diuji | Widget test menggunakan `MaterialApp(home: ...)`, tanpa router dan tanpa membuka detail. Test detail lama hanya memeriksa konten. | Terima | Perubahan navigasi dapat merusak alur kembali tanpa terdeteksi test yang tersedia. |
| AC-02 | Widget test belum menguji query yang cocok | Input yang diuji hanya `judul tidak tersedia`; belum ada pemeriksaan judul hasil pencarian yang cocok. | Terima | Unit test domain belum membuktikan bahwa input dan hasil terhubung dengan benar pada UI. |

| ID | Usulan | Keputusan | Alasan teknis |
|---|---|---|---|
| OP-01 | Test membuka ulang daftar setelah ditutup | Ditunda | Persistensi query setelah keluar ke Home belum menjadi kriteria fitur. Test kembali dari detail yang diwajibkan sudah tersedia. |
| OP-02 | Menampilkan jumlah hasil pencarian | Ditolak untuk cakupan saat ini | Data hanya tiga pengumuman. Daftar hasil dan empty state sudah memenuhi kebutuhan; label jumlah menambah tampilan dan assertion tanpa kebutuhan fungsional tambahan. |

## 10. Keputusan per file

Kode produksi diterima karena pembagian layer sudah sesuai. Test diterima dengan penambahan cakupan untuk AC-01 dan AC-02.

## 11. Hasil pemeriksaan akhir

![AI Analyze and Test](../screenshots/analyze_test_success.png)
