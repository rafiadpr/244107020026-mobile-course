# Verifikasi UI Praktikum 3

Perangkat: Redmi Note 9 Pro, Android 12. Screenshot asli diambil dari aplikasi melalui ADB pada 14 Oktober 2026, tanpa mengubah gambar.

| Halaman | Sebelum Praktikum 3 | Sesudah Praktikum 3 |
| --- | --- | --- |
| Login | [before](praktikum3_before_login.png) | [after](praktikum3_after_login.png) |
| Home | [before](praktikum3_before_home.png) | [after](praktikum3_after_home.png) |
| Pengumuman #42 | [before](praktikum3_before_announcement.png) | [after](praktikum3_after_announcement.png) |

Sesi uji versi sesudah refactor: 21:25–21:31 WIB (lebih dari lima menit). Diuji: sesi login tetap tersedia setelah aplikasi dijalankan ulang, logout kembali ke Login, email tanpa @ memunculkan pesan validator lama, email demo dipulihkan, login kembali ke Home, membuka Pengumuman #42, kembali ke Home dan membuka halaman Debug FCM. Kegagalan repository dan retry UI diuji melalui fake repository pada widget/provider test.

Label dan bounds elemen aplikasi pada hierarchy UI Login, Home dan Pengumuman identik sebelum/sesudah. Status bar/jam/baterai perangkat berbeda sesuai waktu pengambilan; tidak termasuk perbandingan layout aplikasi.

FCM menghasilkan `FCM Registration failed!` baik sebelum maupun sesudah refactor. Halaman Debug FCM tetap dapat dibuka; pengiriman notifikasi, refresh token perangkat dan subscribe topik tidak dapat dinyatakan lolos end-to-end tanpa token FCM yang valid. Konfigurasi Firebase tidak diubah pada refactor ini.
