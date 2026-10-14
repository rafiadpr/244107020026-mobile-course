# Prompt AI Challenge

Tanggal evaluasi: 15 Oktober 2026 (WIB).
Checkpoint sebelum challenge: afc868f, sesudah Praktikum 1–3.

## Prompt dari gambar codelab

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

## Konteks aktual yang dipakai

Prompt generik di atas bukan bukti bahwa widget proyek ini memanggil Dio. Hasil audit menunjukkan halaman tidak melakukan HTTP/storage langsung. Pengumuman hanya detail contoh statis dengan ID dari rute; tidak ada daftar atau API pengumuman yang dapat direfaktor.

Instruksi tambahan untuk evaluasi: pertahankan fitur/perilaku yang berjalan; jangan membuat endpoint, CRUD, database, backend FirebaseAuth atau fetch pengumuman baru. Uji usulan terhadap kode dan catat keputusan teknis yang dapat ditinjau pengguna.
