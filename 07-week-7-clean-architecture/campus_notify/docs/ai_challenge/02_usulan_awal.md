# Usulan awal AI untuk dievaluasi

## Kandidat struktur penuh

```text
lib/
  core/failures.dart
  core/providers.dart
  features/
    auth/
      domain/entities/auth_session.dart
      domain/repositories/auth_repository.dart
      domain/usecases/login.dart
      domain/usecases/logout.dart
      domain/usecases/get_auth_status.dart
      data/models/auth_session_model.dart
      data/datasources/{mock_auth_data_source,token_store}.dart
      data/repositories/auth_repository_impl.dart
      presentation/providers/auth_provider.dart
      presentation/pages/login_page.dart
    announcements/
      domain/entities/announcement.dart
      domain/repositories/announcement_repository.dart
      domain/usecases/get_announcements.dart
      data/models/announcement_model.dart
      data/repositories/announcement_repository_impl.dart
      presentation/providers/announcement_provider.dart
      presentation/pages/announcement_page.dart
  routes.dart
```

Kandidat memisahkan entity, kontrak, implementasi dan UI; repository mendapat dependency melalui provider Riverpod dan mengembalikan Record sukses/gagal.

Kandidat membungkus setiap operasi repository dengan class use case dan mengisi Domain/Data announcements agar bentuk dua fitur seragam. Keuntungannya struktur mudah dikenali dan siap untuk aturan yang lebih kompleks. Biayanya lebih banyak file/indirection, bahkan bila use case hanya satu baris dan belum ada sumber data announcement.

Untuk FCM, kandidat memindahkan PushService ke Data announcements, FcmNotifier/DebugTokenPage ke Presentation announcements, serta memisahkan payload navigasi dari adapter SDK. Ini menyatukan kode pengumuman/notifikasi, tetapi pemindahan saja tidak menyelesaikan coupling Data ke routes; perlu adapter event/navigation yang benar.

## Kelemahan yang harus ditolak/diperbaiki

- Model/repository/fetch announcements belum mempunyai kode lama untuk dipindahkan.
- Tiga use case auth hanya meneruskan call; tidak menambahkan aturan bisnis atau menggabungkan repository.
- Memindahkan PushService tanpa memisahkan navigasi hanya mengganti nama folder.
- Folder/class kosong demi simetri menambah boilerplate.
- Mengganti mock auth dengan FirebaseAuth atau membuat API baru melanggar scope refactor.

Kandidat tidak diterapkan seluruhnya. Keputusan dan penerapan minimal ada di 03_keputusan.md.
