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

2. Verifikasi 6 langkah

3. Contoh test bukti

### Bukti wajib


# Praktikum 3: Debug dan refactor

1. Debug dengan test merah

2. Refactor ke layer yang benar

3. Verifikasi akhir


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

