# Pemetaan semua file lama

Daftar file lama berasal dari lib pada snapshot ddb8197 (13 file), bukan dari contoh notes yang tidak ada di campus_notify. Tujuan merupakan keputusan akhir untuk fitur auth atau usulan yang diberi status eksplisit.

| File lama | Tujuan baru / tujuan usulan | Aksi | Status | Alasan |
| --- | --- | --- | --- | --- |
| data/auth_repository.dart | features/auth/domain/entities/auth_session.dart; domain/repositories/auth_repository.dart; data/repositories/auth_repository_impl.dart; data/datasources/mock_auth_data_source.dart | Pecah lalu hapus file campuran | Diterapkan | Entity, kontrak, IO dan simulasi berbeda tanggung jawab; mock tetap sama |
| data/token_store.dart | features/auth/data/datasources/token_store.dart | Pindah | Diterapkan | Token IO berada pada Data; DI menyediakan instance bersama |
| providers/auth_provider.dart | features/auth/presentation/providers/auth_provider.dart; core/providers.dart | Pecah/pindah | Diterapkan | Wiring auth terpusat dan state tidak mengakses storage; wrapper use case dihapus pada AI Challenge |
| pages/login_page.dart | features/auth/presentation/pages/login_page.dart | Pindah | Diterapkan | UI login mengikuti fitur auth, tanpa akses Data |
| pages/announcement_page.dart | features/announcements/presentation/pages/announcement_page.dart; presentation/providers/announcement_provider.dart; core/presentation/formatters/date_labels.dart | Pindah/pecah derivasi tanggal | Diterapkan | Konten tetap statis; tidak membuat repository/API baru |
| data/api_client.dart | data/api_client.dart saat ini; core/network/api_client.dart bila dipakai fitur lain | Pertahankan; pindah opsional | Belum dipindah ke core | IO sudah terpisah dari UI; pindah ke core tanpa konsumen lain hanya kosmetik. Interceptor memakai kontrak Domain |
| data/api_errors.dart | data/api_errors.dart saat ini; mapper exception di Data dan message mapper Presentation bila diintegrasikan | Pecah bersyarat | Belum diterapkan | Helper hanya digunakan test; jangan membuat mapper/class baru sebelum ada pemanggil nyata |
| providers/fcm_provider.dart | providers/fcm_provider.dart saat ini; features/announcements/presentation/providers/fcm_provider.dart bila scope FCM disatukan | Pindah bersyarat | Belum diterapkan | State/masking cocok di Presentation; perlu menilai lifecycle service dahulu |
| messaging/push_service.dart | messaging/push_service.dart saat ini; adapter SDK Data announcements dan event/coordinator Presentation | Pecah, bukan sekadar pindah | Belum diterapkan | SDK/storage/HTTP tidak boleh bergantung pada GoRouter/widget; Data -> routes saat ini merupakan utang arsitektur |
| pages/debug_token_page.dart | pages/debug_token_page.dart saat ini; features/announcements/presentation/pages/debug_token_page.dart bila disatukan dengan FCM | Pindah opsional; ekstrak formatting | Formatting diterapkan, pindah folder ditunda | Halaman merupakan alat debug FCM, bukan entity bisnis. Membuat fitur domain debug tersendiri berlebihan |
| pages/home_page.dart | pages/home_page.dart atau shell presentation bersama | Pertahankan | Diterapkan | Home menghubungkan fitur, bukan implementasi auth/announcements |
| main.dart | main.dart untuk bootstrap; konfigurasi router ke routes.dart | Pecah | Diterapkan | Bootstrap Firebase/ProviderScope tetap, rute lebih mudah diaudit |
| routes.dart | routes.dart; payload mapping ke adapter/coordinator Presentation saat FCM dipisah | Pertahankan; pecah bersyarat | Router terpusat, pemisahan payload ditunda | Kedua alias/guard dipertahankan; payload data ke URL adalah navigasi, bukan aturan entity auth |

## File tambahan dari praktikum yang dievaluasi

| File | Keputusan |
| --- | --- |
| core/failures.dart | Pertahankan: tipe murni yang dipakai kontrak dan implementasi |
| core/providers.dart | Pertahankan: dependency bersama, bukan tempat semua wiring fitur |
| core/presentation/formatters/date_labels.dart | Pertahankan: formatting UI di Presentation |
| features/auth/data/models/auth_session_model.dart | Pertahankan sebagai batas serialisasi praktikum; jangan mengada-ada DTO tambahan |
| features/auth/domain/usecases/login.dart | Hapus: wrapper satu operasi repository tanpa aturan tambahan |
| features/auth/domain/usecases/logout.dart | Hapus: wrapper satu operasi repository tanpa aturan tambahan |
| features/auth/domain/usecases/get_auth_status.dart | Hapus: wrapper satu operasi repository tanpa aturan tambahan |
| messaging/providers.dart | Pertahankan: composition root bersama untuk HTTP/FCM; bukan Domain |
| test/auth_layers_test.dart | Perbarui pemanggil langsung melalui repository; kontrak/perilaku diuji tetap sama |
| test/presentation_test.dart | Pertahankan: override kontrak, loading/error/retry dan label tetap berlaku |

## Target bila pemisahan FCM kelak benar-benar dikerjakan

```text
features/announcements/
  data/datasources/push_service.dart
  presentation/providers/fcm_provider.dart
  presentation/pages/debug_token_page.dart
  presentation/notification_navigation_coordinator.dart
```

Adapter Data harus meneruskan event bernilai Dart/kontrak callback, bukan menentukan navigasi UI. Domain/repository notifikasi hanya ditambahkan bila operasi/kebijakan yang sekarang berkumpul di service perlu kontrak yang stabil. Tidak ada AnnouncementRepository untuk konten statis.
