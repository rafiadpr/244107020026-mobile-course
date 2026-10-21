# AI Challenge — Review dan Keputusan

## Prompt

```text
Review perubahan validasi token FCM sebagai senior Flutter developer.
Konteks: Clean Architecture, Riverpod, GoRouter, Dio, Firebase/FCM.
Fokus pada kebenaran, arsitektur, dan tes. Abaikan style.
Berikan lima temuan atau saran beserta level, alasan, dan usulan perbaikan.
```

## Hasil review dan keputusan

Semua poin berikut berlevel **saran**, bukan blocker. Dua kekurangan tes ditemukan; tiga alternatif perubahan kode dinilai tidak sesuai.

| No. | Saran awal AI | Keputusan dan alasan | Bukti |
| --- | --- | --- | --- |
| 1 | Tambah tes saat pengambilan token gagal setelah penghapusan berhasil pada force refresh. | **Diterima.** Kombinasi ini belum ada di tes permanen. Tes perlu memastikan proses berhenti sebelum sync. | Tes sementara lulus: failure diteruskan dan hanya delete/get dipanggil. |
| 2 | Tambah tes saat token baru kosong/spasi setelah penghapusan berhasil. | **Diterima.** Tes kosong/spasi yang ada belum memakai force refresh. | Dua tes sementara lulus: LocalFailure muncul dan sync tidak dipanggil. |
| 3 | Kirim token menggunakan `syncToken(token.trim())`. | **Ditolak.** Cukup periksa kekosongannya; nilai token yang dikirim tetap dipertahankan. | Tes token valid memeriksa token diteruskan utuh dan lulus. |
| 4 | Panggil Firebase langsung dari RegisterDevice. | **Ditolak.** Domain harus memakai kontrak repository, bukan SDK Firebase. | Grep Domain tidak menemukan import package, Data, atau Presentation. |
| 5 | Periksa token masukan sebelum menjalankan force refresh. | **Ditolak.** Force refresh mengabaikan token lama dan mengambil token baru. Pemeriksaan terlalu awal bisa menolak proses yang valid. | Tes sementara dengan token masukan kosong dan token baru valid tetap berhasil. |

Dua saran yang diterima adalah tambahan cakupan tes, bukan bug baru pada kode. Tes tersebut **belum ditambahkan permanen**.

Contoh pemeriksaan untuk kedua saran tes:

```dart
// Setelah force refresh gagal mengambil token atau mendapat token kosong:
expect(result.registration, isNull);
expect(repo.calls, ['delete', 'get']); // sync tidak boleh dipanggil
// Periksa juga failure sesuai kasusnya.
```

## Bukti verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter test --no-pub` | 44 lulus: 40 tes permanen + 4 tes sementara. File tes sementara sudah dihapus. |
| `flutter analyze --no-pub` | Tidak ada masalah. |
| `dart format --output=none --set-exit-if-changed lib test` | 33 file diperiksa, 0 perubahan setelah tes sementara dihapus. |
| Pemeriksaan kode dan grep | Dua kombinasi tes belum ada; Domain tetap bebas SDK Firebase dan layer luar. |

Pengujian dilakukan dari `07-week-7-clean-architecture/campus_notify`. Tidak ada uji push FCM end-to-end baru pada review ini.

## AI Verification Checklist

- [x] Temuan diperiksa melalui kode, grep, dan tes.
- [x] Dua kekurangan cakupan tes terbukti dan dicatat.
- [x] Saran yang melanggar dependency rule ditolak.
- [x] Style diserahkan ke formatter/CI, bukan dianggap bug.
- [x] Minimal satu saran ditolak dengan alasan tertulis; ada tiga penolakan.
- [x] Prompt, saran awal, keputusan, dan bukti uji disimpan di dokumen ini.
- [ ] Tambahkan dua saran tes yang diterima ke tes permanen dan uji ulang.
- [ ] Mahasiswa membaca keputusan dan dapat menjelaskan alasannya saat demo.
