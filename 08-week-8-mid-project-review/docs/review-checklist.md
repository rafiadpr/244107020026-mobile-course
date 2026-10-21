# Review checklist Modul 8

Dokumen laporan pendamping README. Centang setelah ada bukti pelaksanaan.

## Praktikum 1 — Audit dan commit

Audit awal menemukan hanya main lokal dan origin/main. Kondisi terbaru sudah memiliki develop dan branch kerja fix/fcm-token-validation.

| Hal yang diaudit | Catatan |
| --- | --- |
| Riwayat main | Commit lama ada pada main; perlu riwayat PR GitHub untuk memastikan apakah dahulu langsung di-commit ke main. |
| Pesan commit | Tiga contoh perbaikannya ada pada tabel di bawah. |
| Branch lama >1 minggu | Tidak ada feature branch lokal pada audit awal; belum diverifikasi dari aktivitas GitHub. |
| File belum terlacak | Konfigurasi Firebase dan screenshot Minggu 6 perlu diputuskan pelacakannya; dokumen Minggu 8 perlu ditambahkan secara selektif. |
| Perubahan kecil + tes | Selesai: commit a2173b6 pada fix/fcm-token-validation. |
| Push branch | Belum diverifikasi dari GitHub. |

### Simulasi tiga pesan commit

Cukup tabel sebelum/sesudah. Riwayat commit asli tidak diubah.

| Hash | Pesan asli | Usulan pesan | Alasan |
| --- | --- | --- | --- |
| `2d5cf12` | `docs : refleksi on readme` | `docs(architecture): add week 7 architecture reflection` | Scope dan isi refleksi jelas, tanpa spasi sebelum titik dua. |
| `ffc04da` | `feat : add auth push test for testing push` | `test(auth): add auth and push test coverage` | Perubahan hanya menambahkan file tes. |
| `8e9c822` | `feat : add new code on api_client, push_service, main for Refactoring, testing, dan error umum` | `refactor(messaging): reorganize API and push integration` | Ringkas dan menyebut tujuan/area perubahan. |