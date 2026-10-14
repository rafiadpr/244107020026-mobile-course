# Usulan dibandingkan dengan keputusan teknis

| Usulan | Keputusan teknis | Alasan / trade-off | Status |
| --- | --- | --- | --- |
| Entity/kontrak auth di Domain; implementasi di Data | Terima | Kontrak murni, implementasi dapat diganti fake; ada biaya beberapa file yang mempunyai tanggung jawab jelas | Diterapkan |
| Record untuk sukses/gagal | Terima | SDK exception tidak bocor; pemanggil wajib membedakan hasil null dan Failure | Diterapkan |
| Use case untuk semua method auth | Tolak wrapper satu-baris | Login/Logout/GetAuthStatus hanya mendelegasikan repository. Notifier sekarang memanggil kontrak langsung; tiga class dan provider perantara dihapus | Diterapkan pada challenge |
| Model auth terpisah | Pertahankan sesuai batas serialisasi praktikum | Entity tetap murni dan Data mengeluarkan entity; manfaat runtime mapping saat backend masih mock terbatas. Jangan menggandakan DTO tambahan tanpa schema nyata | Diterapkan; trade-off pedagogis dicatat |
| Domain/Data lengkap untuk announcements | Tolak saat ini | Konten masih statis. Membuat repository/model/endpoint berarti menambah fitur, bukan refactor | Tidak dibuat |
| Provider label tanggal untuk pengumuman | Terima | Memindahkan derivasi keluar dari build dan memungkinkan clock fake tanpa membuat entity/API | Diterapkan |
| DI dengan Riverpod | Terima | Reuse dependency dan override fake, tanpa package locator tambahan; Data import hanya dibolehkan pada file wiring | Diterapkan |
| Semua wiring masuk satu provider global | Tolak | Wiring auth di provider fitur; shared store/clock di core; HTTP/FCM di messaging provider. Mengurangi ketergantungan lintas fitur | Diterapkan |
| Pindahkan FCM ke announcements | Usulan lanjutan bersyarat | Pengumuman dan notifikasi terkait, tetapi listener/isolate/navigasi perlu dipisahkan lebih dahulu. Pindah folder saja tidak cukup | Belum diterapkan |
| Buat abstract data source/factory untuk semua class | Tolak | Constructor injection yang ada cukup untuk fake. Tambahkan abstraksi jika ada beberapa sumber/implementasi yang benar-benar diperlukan | Tidak ditambah |

## Struktur final yang benar-benar ada

```text
lib/
  core/
    failures.dart
    providers.dart
    presentation/formatters/date_labels.dart
  features/
    auth/
      domain/entities/auth_session.dart
      domain/repositories/auth_repository.dart
      data/models/auth_session_model.dart
      data/datasources/mock_auth_data_source.dart
      data/datasources/token_store.dart
      data/repositories/auth_repository_impl.dart
      presentation/providers/auth_provider.dart
      presentation/pages/login_page.dart
    announcements/
      presentation/providers/announcement_provider.dart
      presentation/pages/announcement_page.dart
  data/{api_client,api_errors}.dart
  messaging/{providers,push_service}.dart
  providers/fcm_provider.dart
  pages/{home_page,debug_token_page}.dart
  main.dart
  routes.dart
```

## Batas penerapan

Pemisahan internal PushService, coupling ke routes, pemetaan ApiErrors ke pesan presentation, dan perbaikan konfigurasi registrasi FCM belum dilakukan pada challenge ini. Coupling ditemukan dan dicatat, tidak dinyatakan bersih hanya karena grep Domain lulus. Firebase registration gagal pada uji perangkat praktikum sebelumnya; tidak diuji ulang pada perubahan ini.
