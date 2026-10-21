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

## Praktikum 2 — PR dan peer review

- [ ] PR kecil menargetkan develop; isi masalah, solusi, cara uji dan issue yang benar.
- [ ] Review pasangan mencakup dua temuan correctness, satu arsitektur, satu tes dan satu saran keterbacaan.
- [ ] Komentar mengikuti observasi → dampak → usulan konkret.
- [ ] Semua request changes ditindaklanjuti; keputusan akhir reviewer sudah approve.
- [ ] Merge setelah pemeriksaan hijau; issue ditutup dan branch dibersihkan.

URL issue: belum diisi. URL PR: belum diisi. Reviewer/approval/merge: belum diisi.

## Praktikum 3 — Static analysis dan mid review

| Pemeriksaan | Bukti saat ini |
| --- | --- |
| Analyze | No issues found pada perubahan validasi token. |
| Format seluruh proyek | Belum dicatat; dua file perubahan sudah diformat. |
| Test | 11 tes terarah dan seluruh 40 tes lulus. |
| Tiga grep sterilitas Minggu 7 | Belum dijalankan ulang pada Modul 8. |
| CI | Template tersedia, workflow aktif belum dipasang melalui panduan ini. |
| README, screenshot, cara run | Perlu dilengkapi untuk Modul 8. |
| Perilaku aplikasi setara akhir Minggu 7 | Uji manual ulang belum dilakukan. |

## AI Challenge

- [ ] Prompt dan output awal AI tersimpan.
- [ ] Semua temuan diperiksa dengan kode/grep, tes gagal atau reproduksi manual.
- [ ] Minimal dua temuan terbukti benar, minimal satu ditolak dengan alasan dan bukti.
- [ ] Tabel keputusan final terisi dan dapat dijelaskan oleh mahasiswa.

Laporan: [ai-review-vs-keputusan.md](ai-review-vs-keputusan.md).

## Refactoring, testing, dan verifikasi mandiri

- [ ] Minimal tiga komentar review bermakna ditindaklanjuti hingga approve.
- [ ] Style berulang ditangani formatter/CI.
- [ ] PR >300 baris dipecah menjadi dua atau tiga PR kecil; jika tidak ada, catat tidak berlaku dan ukuran aktual.
- [ ] Reviewer menjalankan analyze/test serta uji manual sekitar lima menit per fitur + screenshot.
- [ ] Branch dari develop, PR kecil satu fitur, issue ditutup melalui PR.
- [ ] Analyze, format dan test hijau pada versi akhir.
- [ ] README berisi status tengah semester dan peta issue/PR.