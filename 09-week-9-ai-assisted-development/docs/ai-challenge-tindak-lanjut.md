Tindak lanjut AC-01 dan AC-02 selesai. Kode produksi tidak berubah; seluruh test lama dipertahankan.

File yang ditambah/diubah:
- Baru: [announcement_navigation_test.dart](E:/Code/mob_dev/244107020026-mobile-course/09-week-9-ai-assisted-development/campus_notify/test/announcement_navigation_test.dart) — dua test AC-01:
  - Home → daftar → cari seminar → detail ID 44 → tombol kembali AppBar. Memastikan query tetap seminar, judul seminar tampil, dan dua judul lainnya tidak tampil.
  - Detail dibuka langsung tanpa riwayat; tombol kembali menuju Home.
- Diubah: [announcement_list_page_test.dart](E:/Code/mob_dev/244107020026-mobile-course/09-week-9-ai-assisted-development/campus_notify/test/announcement_list_page_test.dart) — satu test AC-02 untuk input '  BEASISWA  ', dengan seluruh assertion yang diminta.
Test navigasi menggunakan routerProvider aplikasi sebenarnya, fake repository auth, serta teardown router dan container. Test baru tidak menginisialisasi listener FCM atau memakai layanan asli.
Pemeriksaan	Hasil aktual
Dua file test baru/berubah	4 test lulus, exit 0
flutter analyze	No issues found, exit 0
dart format --set-exit-if-changed lib test	43 file, 0 berubah, exit 0
flutter test	57 test lulus, exit 0


Tidak ditemukan bug yang memerlukan perbaikan produksi. Smoke test lama tetap mencetak log Firebase belum diinisialisasi, tetapi lulus.

Navigasi sudah diverifikasi melalui widget test; pengujian manual pada perangkat dan screenshot belum dilakukan. README, AI log, dan refleksi tidak diubah.