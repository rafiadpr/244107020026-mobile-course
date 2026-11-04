# Praktikum: Chat interface dengan AI

1. Tambahkan dependensi

```yaml
http: ^1.2.0
flutter_secure_storage: ^11.2.0
flutter_riverpod: ^3.4.3
image_picker: ^1.2.4
record: ^7.1.2
path_provider: ^2.1.5
```

Versi `flutter_secure_storage` dan `flutter_riverpod` mengikuti proyek pertemuan 7. `flutter_riverpod` digunakan untuk widget Flutter dan provider tanpa menambah paket `riverpod` secara terpisah.

2. Buat AI service

Implementasi di [lib/ai/ai_service.dart](campus_notify/lib/ai/ai_service.dart).

| Method | Fungsi |
| --- | --- |
| `saveApiKey()` | Menyimpan kunci ke secure storage |
| `deleteApiKey()` | Menghapus kunci dan cache jawaban |
| `askStream()` | Membaca potongan respons SSE dari Gemini |
| `ask()` | Menggabungkan respons menjadi satu teks |
| `recognizeText()` | Mengambil teks dari gambar |
| `speechToText()` | Mengubah rekaman menjadi teks |
| `describeImage()` | Membuat deskripsi singkat gambar |

Model bawaan adalah `gemini-3.5-flash-lite`. API key dikirim melalui header `x-goog-api-key`, bukan ditulis pada kode sumber atau URL. Service menggunakan `streamGenerateContent` untuk chat dan `generateContent` untuk file.

3. Buat chat screen

Implementasi di [lib/features/chat_screen.dart](campus_notify/lib/features/chat_screen.dart).

Halaman berisi daftar pesan, kolom pertanyaan, tombol kirim, indikator loading, dan pilihan FAQ offline. Jawaban bertambah mengikuti potongan respons server. Tombol kirim dinonaktifkan selama permintaan berjalan agar tidak ada pengiriman ganda.

Jika terjadi kesalahan, halaman menampilkan pesan yang mudah dipahami, tombol `Coba lagi`, dan tombol `Gunakan FAQ offline`. Pertanyaan yang mengandung pola nomor panjang atau email ditolak sebelum dikirim.

4. Pengaturan API key

Halaman [Pengaturan AI](campus_notify/lib/features/ai_settings_screen.dart) dibuka melalui ikon pengaturan pada chat. Input kunci disamarkan dan dibersihkan setelah disimpan. Kunci yang sudah tersimpan tidak ditampilkan kembali. Tombol hapus menghapus kunci dari perangkat.

5. Menjalankan aplikasi

```bash
cd 10-week-10-ai-feature-integration/campus_notify
flutter pub get
flutter run
```

Alur penggunaan:

- Masuk melalui halaman login Campus Notify.
- Pilih `Buka Asisten Kampus` pada halaman utama.
- Buka `Pengaturan AI`, masukkan API key Gemini, lalu tekan `Simpan`.
- Kembali ke chat dan ketik pertanyaan tanpa data pribadi.
- Aktifkan `FAQ offline` untuk memakai jawaban lokal tanpa koneksi AI.

Model dapat diganti saat menjalankan aplikasi:

```bash
flutter run --dart-define=GEMINI_MODEL=gemini-3.5-flash-lite
```

Pada Android, minimum SDK ditetapkan setidaknya 24 sesuai kebutuhan `image_picker`. Plugin Google Services hanya diaktifkan jika `android/app/google-services.json` tersedia. Chat dan FAQ dapat dipakai tanpa konfigurasi FCM; notifikasi Firebase memerlukan konfigurasi Firebase yang sesuai. Berkas konfigurasi tersebut tidak disertakan dalam salinan tugas.


