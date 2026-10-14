# Refactoring dan testing

Fitur kedua memakai notifikasi pengumuman yang sudah ada. Tidak menambah API daftar pengumuman atau fitur notes.

- Domain: DeviceRegistration, kontrak AnnouncementRepository, dan RegisterDevice.
- Data: PushService lama dipindahkan, model untuk payload, dan implementasi repository.
- Presentation: provider mengatur DI/state; halaman Debug FCM tetap membaca state.
- core/format.dart berisi formatting tanggal dan parsing route yang bisa diuji tanpa widget.

RegisterDevice dipakai untuk mengambil token lalu sinkronisasi. Saat force refresh, token dihapus terlebih dahulu. Use case ini berguna karena mengatur beberapa langkah; auth tetap langsung memakai kontrak repository untuk operasi sederhana.

Exception ditangani di Data menjadi Failure. UI hanya menerima pesannya. Simulasi backend /devices dari modul sebelumnya tetap dipakai; status sinkronisasi pada mode demo bukan bukti backend nyata berhasil.

Tes utama ada di test/register_device_test.dart: sukses, gagal membaca token, dan urutan force refresh menggunakan repository palsu. test/core_format_test.dart menguji fungsi format dan parser.

Jalankan:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Hasil: analyzer bersih, 32 tes lulus. Hasil grep ada di [verification.txt](verification.txt).

| Halaman | Sebelum | Sesudah |
| --- | --- | --- |
| Home | [Screenshot](../../screenshots/refactor_before_home.png) | [Screenshot](../../screenshots/refactor_after_home.png) |
| Pengumuman | [Screenshot](../../screenshots/refactor_before_announcement.png) | [Screenshot](../../screenshots/refactor_after_announcement.png) |
| Debug FCM | [Screenshot](../../screenshots/refactor_before_debug.png) | [Screenshot](../../screenshots/refactor_after_debug.png) |

Layout tetap sama; jam dan waktu pembaruan dapat berubah.

Uji Redmi Note 9 Pro: token tersedia, subscribe/unsubscribe topik dan force refresh berjalan. Pengiriman push dari server belum diuji end-to-end.
