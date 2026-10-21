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
- Workflow sudah disiapkan pada [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). CI berjalan setelah file di-commit dan di-push pada PR ke develop.
- Salinan template ada pada [`templates/ci.yml`](templates/ci.yml).

3. Nilai kesiapan tengah semester
- Docs ada pada [`docs/review-checklist.md`](docs/review-checklist.md)

| Pemeriksaan | Bukti saat ini |
| --- | --- |
| Analyze | No issues found pada perubahan validasi token. |
| Format kode | Pemeriksaan `lib test` lulus: 33 file, 0 perubahan. |
| Test | Seluruh 43 tes permanen lulus setelah tiga tes tambahan. |
| Tiga grep sterilitas Minggu 7 | Sudah dijalankan ulang: tidak ada kecocokan pada ketiga pencarian. |
| CI | Workflow tersedia di root repository; hasil GitHub Actions belum diverifikasi. |
| README, screenshot, cara run | Perlu dilengkapi untuk Modul 8. |
| Perilaku aplikasi setara akhir Minggu 7 | Uji manual ulang belum dilakukan. |


# AI Challenge

Laporan: [docs/ai-review-vs-keputusan.md](docs/ai-review-vs-keputusan.md).


# Refactoring, testing, dan error umum

## Testing

Jalankan dari `07-week-7-clean-architecture/campus_notify`:

```bash
flutter analyze --no-pub
dart format --output=none --set-exit-if-changed lib test
flutter test --no-pub
```

| Pemeriksaan | Hasil |
| --- | --- |
| Analyze | No issues found. |
| Format `lib test` | 33 file diperiksa, 0 perubahan. |
| Seluruh tes | **43 tes permanen lulus** (40 sebelumnya + 3 tambahan). |

Semua perintah selesai dengan exit code 0 pada kode lokal yang belum di-commit.

## Checklist verifikasi mandiri

- [x] Dua saran tes AI ditindaklanjuti menjadi tiga tes permanen.
- [x] Formatter dipakai dan workflow CI disiapkan.
- [x] Hasil grep sterilitas diperiksa ulang.
- [x] Analyze, format, dan seluruh 43 tes lulus secara lokal.
- [ ] Hasil CI pada GitHub sudah hijau.
- [ ] Minimal tiga komentar review bermakna ditindaklanjuti hingga approve.
- [ ] PR besar dipisah sesuai rencana bila masih diperlukan pada diff GitHub terbaru.
- [ ] Uji manual lima menit per fitur dan screenshot hasilnya tersedia.
- [ ] Issue, PR, dan keputusan merge akhir dicatat dengan tautan nyata.


# Refleksi
1. Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?
LGTM buta berarti menyetujui tanpa memeriksa. Approve yang bertanggung jawab dilakukan setelah membaca kode dan menguji. Jika asal approve, bug bisa lolos dan menyulitkan tim.

2. Kapan komentar wajib berstatus request changes, dan kapan cukup saran?
Request changes diperlukan jika ada bug, pelanggaran arsitektur, atau tes penting yang belum ada. Saran cukup untuk perbaikan kecil yang tidak menghambat fungsi.

3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?
Saya menolak akses Firebase langsung dari Domain karena melanggar arsitektur. Saya juga menolak pemangkasan token karena dapat mengubah nilainya.

4. Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya?
Saya menambahkan tiga tes force refresh setelah review AI. Dampaknya, kegagalan mengambil token dan token baru kosong ikut diperiksa. Review ini dilakukan mandiri, bukan dengan pasangan.
