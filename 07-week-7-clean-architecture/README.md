# Modul 7 — Clean Architecture

## Praktikum 1: Audit layer project lama

Proyek dasar: campus_notify dari Modul 6. Tahap ini hanya audit dan rancangan; kode aplikasi belum dipindahkan atau ditambah fiturnya.

### Snapshot sebelum refactor

Snapshot dasar: `ddb8197 chore: snapshot before clean architecture`.

```powershell
git status --short
git add -- 07-week-7-clean-architecture/campus_notify
git commit -m "chore: snapshot before clean architecture"
```

### Tabel pemetaan layer

Path relatif terhadap direktori campus_notify. Temuan berdasarkan kode sebelum refactor.

| File | Layer saat ini | Masalah / Pelanggaran |
| --- | --- | --- |
| lib/pages/home_page.dart | Presentation | Logout sudah melalui notifier; tidak ditemukan Dio/storage langsung. Literal rute dapat dirapikan. |
| lib/data/api_client.dart | Data | HTTP/interceptor sudah di luar UI, tetapi bergantung pada repository auth konkret. Pertahankan refresh/retry satu kali. |
| lib/providers/auth_provider.dart | Presentation + DI + Data | Perakitan repository/client bercampur dengan state. Notifier membaca, menyimpan dan menghapus token langsung. |
| lib/data/auth_repository.dart | Data + calon entity Domain | AuthSession dan repository konkret berada dalam satu file; belum ada kontrak abstract Domain. |
| lib/data/token_store.dart | Data | Wrapper secure storage tepat di Data, tetapi dipanggil langsung oleh notifier. |
| lib/pages/login_page.dart | Presentation | Login sudah melalui notifier. Validator form mengulang aturan mock; tetap bedakan UI form dan aturan sumber auth. |
| lib/providers/fcm_provider.dart | Presentation + DI + service | Wiring PushService bercampur dengan state; notifier mengorkestrasi token/sync/topik menggunakan service konkret. |
| lib/messaging/push_service.dart | Data/platform + routing | FCM/storage/HTTP dan mapping rute berkumpul. Background handler harus tetap top-level dan tidak memakai widget context. |
| lib/pages/announcement_page.dart | Presentation + formatting | DateTime.now() dipanggil tiga kali di build. Konten masih contoh statis; tidak ada sumber pengumuman yang perlu dibuat. |
| lib/pages/debug_token_page.dart | Presentation | Konversi waktu lokal dilakukan di build; masking sudah berada di state. Clipboard adalah interaksi UI. |
| lib/data/api_errors.dart | Data + pesan presentation | Mapping DioException bercampur dengan pesan pengguna; helper dipakai test. |
| lib/routes.dart | Presentation/routing | Konstanta/payload mapping sudah terpusat; service Data mengimpor routing UI. |
| lib/main.dart | Bootstrap + Presentation | RouterProvider masih berada di main; dapat dipindahkan ke routes.dart tanpa mengubah guard/alias rute. |

### Tiga pelanggaran klasik

Jalankan dari campus_notify. Regex adalah penyaring kandidat, bukan parser build Dart.

```powershell
rg -n -g '*.dart' 'Dio\(|openDatabase|FlutterSecureStorage|SharedPreferences\.getInstance|tokenStoreProvider' lib/pages lib/providers
rg -n -g '*.dart' 'DateFormat|jsonDecode|DateTime\.now\(|\.toLocal\(' lib/pages
rg -n -g '*.dart' 'Repository\(|Dio\(BaseOptions|buildApiClient\(' lib/pages lib/providers
```

Tidak ada akses SDK jaringan/storage langsung di halaman. Pelanggaran nyata ada pada akses TokenStore dalam AuthNotifier, derivasi tanggal di halaman pengumuman, serta wiring yang bercampur dengan notifier. Constructor pada composition root diperbolehkan; interpolasi judul sederhana bukan aturan bisnis.

### Struktur target feature-first

```text
lib/
  core/
    failures.dart
    providers.dart
  features/auth/
    domain/
      entities/auth_session.dart
      repositories/auth_repository.dart
      usecases/login.dart
      usecases/logout.dart
      usecases/get_auth_status.dart
    data/
      models/auth_session_model.dart
      datasources/mock_auth_data_source.dart
      datasources/token_store.dart
      repositories/auth_repository_impl.dart
    presentation/
      providers/auth_provider.dart
      pages/login_page.dart
  routes.dart
```

Urutan: pisahkan entity/kontrak/model dan implementasi auth; pindahkan akses token ke repository; sambungkan pemanggil lama ke Record/use case; rapikan DI/presentation; verifikasi dependency, analyzer dan test. Tidak menambahkan notes/SQLite atau fetch pengumuman karena fitur tersebut tidak ada dalam campus_notify. Target nol akses data mentah/formatting di Presentation diverifikasi pada Praktikum 3.
