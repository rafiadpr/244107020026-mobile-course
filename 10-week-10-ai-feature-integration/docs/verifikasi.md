# Verifikasi pertemuan 10

1. Lingkungan dan metode

Pemeriksaan dijalankan pada 4 November 2026 menggunakan Flutter di Windows. Proyek dasar berasal dari `07-week-7-clean-architecture/campus_notify`.

Pengujian layanan menggunakan `MockClient` dari package `http`. Secure storage memakai penyimpanan tiruan untuk test. Widget chat memakai service tiruan yang mengirim potongan respons atau error secara terkontrol. Tidak ada API key asli atau data pribadi yang dipakai dalam pengujian.

2. Bukti pemeriksaan

| Perintah | Bukti |
| --- | --- |
| `flutter analyze` | [Flutter Analyze](../screenshots/flutter_analyze.png) |
| `dart format --output=none --set-exit-if-changed lib test` | [Dart Format](../screenshots/dart_format.png) |
| `flutter test --reporter expanded` | [Flutter Test](../screenshots/flutter_test.png) |

Hasil akhir: analyzer bersih, 40 file lolos pemeriksaan format tanpa perubahan, dan seluruh 65 test lulus. Sebanyak 22 test mencakup service AI, FAQ, dan widget chat; 43 test lainnya berasal dari proyek dasar.

3. Pemeriksaan perilaku

| Kasus | Hasil yang diuji |
| --- | --- |
| Respons streaming | Dua potongan ditampilkan secara bertahap dan digabung menjadi jawaban |
| Loading | Indikator muncul dan tombol kirim tidak dapat ditekan |
| API error | Pesan ramah, tombol coba lagi, dan pilihan FAQ offline tersedia |
| Fallback | Memilih FAQ setelah API gagal memberikan jawaban lokal tanpa request kedua |
| Input sensitif | Nomor panjang dan email ditolak sebelum request |
| Cache | Pertanyaan yang sama hanya melakukan satu request |
| Batas sesi | Request ke-21 ditolak sebelum memanggil API |
| Validasi respons | Respons kosong, diblokir, atau terpotong ditolak |
| Media | Byte file dikirim sebagai base64 dengan prompt dan MIME type yang sesuai |
| Batas file | File lebih dari 5 MB ditolak sebelum request |

4. Gambar tampilan

Gambar pada folder `screenshots` dihasilkan dari render widget test dengan ukuran 430 × 932. Data respons pada gambar merupakan data simulasi pengujian, bukan hasil panggilan langsung ke Gemini.

Pada Windows, gambar dapat dihasilkan ulang dengan:

```bash
flutter test test/chat_screen_test.dart --dart-define=CAPTURE_SCREENSHOTS=true
```

Mode pengambilan gambar memuat font Arial dari folder font Windows dan Material Icons dari Flutter SDK. Test biasa tidak bergantung pada font sistem tersebut.

5. Batas pengujian

Build APK, panggilan ke layanan Gemini asli, pengambilan gambar melalui kamera fisik, izin perangkat, dan perekaman mikrofon fisik tidak dijalankan pada pengujian otomatis ini. Test media memeriksa isi request dan pengolahan respons. Analyzer dan widget test tidak membuktikan kualitas hasil model atau perilaku plugin pada perangkat fisik.

Filter data sensitif menggunakan pola teks sederhana dan tidak mengenali seluruh jenis data pribadi. Batas request serta cache berlaku selama satu sesi service di memori perangkat. Aplikasi tidak menggunakan backend untuk menetapkan kuota akun atau menyembunyikan kunci milik penyedia layanan.
