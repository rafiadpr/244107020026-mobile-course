# Praktikum 1: Hygiene branch dan commit

1. Audit riwayat Anda
![Git Log](screenshots/Screenshot%202026-10-21%20215253.png)
![Git Branch](screenshots/Screenshot%202026-10-21%20215135.png)
![Git Status](screenshots/Screenshot%202026-10-21%20215227.png)

2. Buat branch kerja yang benar
![Checkout](screenshots/Screenshot%202026-10-21%20215534.png)
![Make Branch](screenshots/Screenshot%202026-10-21%20222747.png)
![Commit on New Branch](screenshots/Screenshot%202026-10-21%20222636.png)
![Make Branch](screenshots/Screenshot%202026-10-21%20222640.png)

3. Perbaiki satu commit buruk (simulasi)

| Hash | Pesan asli | Usulan pesan | Alasan |
| --- | --- | --- | --- |
| `2d5cf12` | `docs : refleksi on readme` | `docs(architecture): add week 7 architecture reflection` | Scope dan isi refleksi jelas, tanpa spasi sebelum titik dua. |
| `ffc04da` | `feat : add auth push test for testing push` | `test(auth): add auth and push test coverage` | Perubahan hanya menambahkan file tes. |
| `8e9c822` | `feat : add new code on api_client, push_service, main for Refactoring, testing, dan error umum` | `refactor(messaging): reorganize API and push integration` | Ringkas dan menyebut tujuan/area perubahan. |


# Praktikum 2: PR dan peer review

1. Buka PR kecil
![Open PR](screenshots/Screenshot%202026-10-21%20224101.png)

2. Review sejawat 15 menit

3. Komentar yang baik

4. Tindak lanjut dan merge
![Merge](screenshots/Screenshot%202026-10-21%20232120.png)


# Praktikum 3: Static analysis dan mid review

1. Bersihkan dengan mesin
![Flutter Analyze](screenshots/Screenshot%202026-10-21%20232353.png)
![Dart Format](screenshots/Screenshot%202026-10-21%20232525.png)
![Flutter Test](screenshots/Screenshot%202026-10-21%20232733.png)

2. Aktifkan penolakan otomatis (CI)
- CI ada pada [`templates/ci.yml`](templates/ci.yml)

3. Nilai kesiapan tengah semester
- Docs ada pada [`docs/review-checklist.md`](docs/review-checklist.md)

| Pemeriksaan | Bukti saat ini |
| --- | --- |
| Analyze | No issues found pada perubahan validasi token. |
| Format seluruh proyek | Belum dicatat; dua file perubahan sudah diformat. |
| Test | 11 tes terarah dan seluruh 40 tes lulus. |
| Tiga grep sterilitas Minggu 7 | Belum dijalankan ulang pada Modul 8. |
| CI | Template tersedia, workflow aktif belum dipasang melalui panduan ini. |
| README, screenshot, cara run | Perlu dilengkapi untuk Modul 8. |
| Perilaku aplikasi setara akhir Minggu 7 | Uji manual ulang belum dilakukan. |


# AI Challenge

Laporan: [docs/ai-review-vs-keputusan.md](docs/ai-review-vs-keputusan.md).


# Refactoring, testing, dan verifikasi mandiri

- [ ] Minimal tiga komentar review bermakna ditindaklanjuti hingga approve.
- [ ] Style berulang ditangani formatter/CI.
- [ ] PR >300 baris dipecah menjadi dua atau tiga PR kecil; jika tidak ada, catat tidak berlaku dan ukuran aktual.
- [ ] Reviewer menjalankan analyze/test serta uji manual sekitar lima menit per fitur + screenshot.
- [ ] Branch dari develop, PR kecil satu fitur, issue ditutup melalui PR.
- [ ] Analyze, format dan test hijau pada versi akhir.
- [ ] README berisi status tengah semester dan peta issue/PR.