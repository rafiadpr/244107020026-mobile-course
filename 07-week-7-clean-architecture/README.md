# Modul 7 — Clean Architecture

## Praktikum 1: Audit layer project lama

Proyek dasar tetap **campus_notify (Modul 6)**. Contoh notes/SQLite pada gambar diterapkan sebagai pola pemisahan tanggung jawab, bukan sebagai fitur baru. Fitur yang dipisahkan pada Praktikum 2 adalah auth: login mock, refresh token, pemeriksaan sesi dan logout yang sudah berjalan.

### Snapshot sebelum refactor

Snapshot sudah tersedia: `ddb8197 chore: snapshot before clean architecture`.

### Pemetaan layer dan item refactor

Tabel mencatat kondisi kode lama pada audit awal dan status sesudah Praktikum 3. Path relatif terhadap direktori campus_notify.

| File lama | Layer saat ini pada audit | Masalah / status refactor |
| --- | --- | --- |
| `lib/pages/home_page.dart` | Presentation | Tidak memanggil Dio/storage; logout melalui notifier. Import notifier sudah diperbarui. |
| `lib/data/api_client.dart` | Data | Interceptor HTTP sudah di luar widget; sekarang memakai kontrak AuthRepository Domain dan menangani Record refresh gagal. |
| `lib/providers/auth_provider.dart` | Presentation + DI + akses Data | Dahulu mengakses TokenStore langsung. Dipindahkan ke features/auth/presentation/providers; notifier hanya memanggil use case dan mengelola AsyncValue. Wiring repository/use case berada pada provider fitur, shared storage di core/providers.dart. |
| `lib/data/auth_repository.dart` | Data + kontrak/entity tercampur | Dipisahkan menjadi entity Domain, abstract repository Record dan AuthRepositoryImpl di Data. Mock lama menjadi MockAuthDataSource. |
| `lib/data/token_store.dart` | Data | Dipindahkan ke features/auth/data/datasources; notifier tidak lagi membaca/menyimpan/menghapus token. |
| `lib/pages/login_page.dart` | Presentation | Dipindahkan ke features/auth/presentation/pages. Validator, pesan form dan login lama dipertahankan. |
| `lib/providers/fcm_provider.dart` | Presentation + orkestrasi service | Wiring HTTP/PushService berada di messaging/providers.dart; notifier memakai service lama dan menyediakan lastUpdatedLabel untuk UI. Pemisahan kontrak FCM lebih lanjut berada di luar fitur auth yang dipilih. |
| `lib/messaging/push_service.dart` | Data/platform + routing | SDK FCM, storage, POST /devices dan mapping route masih berkumpul. Dicatat sebagai item refactor lanjutan; callback/isolate tidak diubah. |
| `lib/pages/announcement_page.dart` | Presentation + formatting tanggal | Dipindahkan ke features/announcements/presentation/pages; tanggal diperoleh dari provider label dengan satu pembacaan clock. Tidak dibuat repository/API pengumuman. |
| `lib/pages/debug_token_page.dart` | Presentation | FCM melalui notifier; halaman menampilkan lastUpdatedLabel dari state, tanpa toLocal() di build. Clipboard tetap interaksi UI. |
| `lib/data/api_errors.dart` | Data + pesan pengguna | Helper Dio lama dipertahankan untuk test; pemisahan mapper pesan menjadi item lanjutan. |
| `lib/routes.dart` | Presentation/routing | Konstanta, routeFromMessage dan GoRouter/routerProvider kini terpusat di sini; kedua alias rute dan guard dipertahankan. |
| `lib/main.dart` | Bootstrap + routing/UI | Konfigurasi router dipindahkan ke routes.dart. Bootstrap Firebase, ProviderScope dan pengaitan FCM tetap berjalan seperti sebelumnya. |

### Tiga pencarian pelanggaran klasik

Jalankan dari direktori campus_notify. Pola mengikuti gambar dan diperluas untuk lokasi presentation baru; folder widgets belum ada, sehingga tidak dicantumkan.

```powershell
# Widget menyentuh jaringan/database/storage langsung
rg -n -g '*.dart' 'Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage' lib/pages lib/features/auth/presentation lib/features/announcements/presentation

# Kandidat transformasi di build: periksa konteks method secara manual
rg -n -g '**/pages/**' -g '**/widgets/**' 'DateFormat|jsonDecode|\.toIso8601String|DateTime\.now\(|\.toLocal\(' lib

# Instansiasi repository atau Dio di UI/provider state
rg -n -g '**/pages/**' -g '**/widgets/**' 'Repository\(|RepositoryImpl\(|Dio\(BaseOptions' lib
```

Hasil setelah refactor:
- Tidak ditemukan akses jaringan/storage langsung atau constructor repository/Dio di folder presentation yang diperiksa.
- Transformasi tanggal sudah diekstrak dari halaman ke formatter/state. Tidak ada DateFormat/jsonDecode di halaman.
- Wiring constructor auth berada di provider fitur; konstruktor implementasi Data di file DI merupakan pengecualian yang memang ditunjukkan contoh Praktikum 3. Halaman/notifier tidak merakit repository.
- Regex hanya mencari kandidat; interpolasi judul sederhana bukan aturan bisnis, dan callback validator bukan kode yang otomatis berjalan saat build.
- Pencarian data mentah dan formatting halaman menghasilkan nol temuan. Ini verifikasi scope auth/Presentation; bukan klaim bahwa semua coupling internal service FCM telah diubah.

### Struktur pada checkpoint Praktikum 3

```text
lib/
  core/
    failures.dart
    providers.dart                    # shared DI / composition root
    presentation/formatters/date_labels.dart
  features/
    auth/
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
    announcements/
      presentation/
        providers/announcement_provider.dart
        pages/announcement_page.dart
  data/
    api_client.dart                    # infrastruktur HTTP lama
    api_errors.dart                    # mapper lama, item audit lanjutan
  messaging/
    providers.dart                    # shared HTTP/FCM wiring
    push_service.dart
  providers/fcm_provider.dart
  pages/
    home_page.dart
    debug_token_page.dart
  routes.dart                          # GoRouter + konstanta + mapping payload
  main.dart
```

## Praktikum 2: Domain dan Data per fitur auth

### Entity murni dan Failure

AuthSession hanya memiliki field final access/refresh dan constructor; tidak mengimpor Flutter, package eksternal, atau mapping. Core Failure tetap sealed dengan LocalFailure dan NetworkFailure (status HTTP opsional). Failure tidak membawa objek exception SDK ke Domain.

### Kontrak abstract dengan Dart Records

Sukses login/refresh: nilai hasil non-null dan failure null. Gagal: hasil null dan failure non-null. Status sesi false dengan failure null berarti belum login; false dengan failure non-null berarti pembacaan storage gagal.

### Model dan implementasi Data

AuthRepositoryImpl menerima MockAuthDataSource dan TokenStore melalui constructor. Try-catch mengubah kegagalan sumber auth/refresh menjadi NetworkFailure dan kegagalan save/read/clear storage menjadi LocalFailure. Simulasi auth Modul 6 tetap menggunakan delay 500/300 ms, aturan email/password lama dan token mock lama. Tidak ditambahkan API Firebase, SQLite atau endpoint baru.

Penyimpanan token saat login, pemeriksaan status dan penghapusan token saat logout berada di repository Data. Interceptor tetap membaca token melalui adapter Data dan menyimpan token hasil refresh; flag isRetry mempertahankan batas retry satu kali. Record refresh gagal ditangani tanpa mengirim exception sumber ke presentation.

### Verifikasi

```powershell
flutter analyze --no-pub
flutter test --no-pub
rg -n 'package:|fromMap|toMap|jsonDecode|/data/|/presentation/' lib/features/auth/domain lib/core/failures.dart
```

Hasil akhir Praktikum 2: analyzer bersih dan seluruh 20 test lulus. Pemeriksaan regex Domain/Failure tidak menemukan import package, mapping atau dependency Data/Presentation.

## Praktikum 3: Presentation, DI dan verifikasi

### 1. Verifikasi dependency rule

```powershell

flutter analyze --no-pub
flutter test --no-pub
```

Hasil: analyzer **No issues found**, seluruh **24 test lulus**. Empat test baru pada test/presentation_test.dart menggunakan override kontrak repository/clock/state untuk loading, error, retry, label tanggal dan masking FCM tanpa plugin nyata. Retry otomatis Riverpod dinonaktifkan hanya pada fixture tes status error agar backoff tidak memperpanjang tes; perilaku aplikasi tidak diubah.

### 2. Verifikasi perangkat dan screenshot

Bukti dan hasil lengkap:

| Halaman | Sebelum | Sesudah |
| --- | --- | --- |
| Login | [Screenshot](campus_notify/screenshots/praktikum3_before_login.png) | [Screenshot](campus_notify/screenshots/praktikum3_after_login.png) |
| Home | [Screenshot](campus_notify/screenshots/praktikum3_before_home.png) | [Screenshot](campus_notify/screenshots/praktikum3_after_home.png) |
| Pengumuman | [Screenshot](campus_notify/screenshots/praktikum3_before_announcement.png) | [Screenshot](campus_notify/screenshots/praktikum3_after_announcement.png) |


## AI Challenge: menilai biaya arsitektur

- [Prompt dan konteks nyata](campus_notify/docs/ai_challenge/01_prompt.md).
- [Usulan awal AI](campus_notify/docs/ai_challenge/02_usulan_awal.md).
- [Tabel usulan vs keputusan, struktur final dan wiring Riverpod](campus_notify/docs/ai_challenge/03_keputusan.md).
- [Pemetaan setiap file lama: pindah/pecah/hapus](campus_notify/docs/ai_challenge/04_pemetaan_file.md).
- [Checklist verifikasi](campus_notify/docs/ai_challenge/05_verifikasi.md).

Keputusan implementasi: Login, Logout dan GetAuthStatus hanya meneruskan satu call repository, sehingga tiga class use case serta provider perantaranya dihapus. AuthNotifier sekarang menggunakan kontrak Domain melalui authRepositoryProvider langsung. Record/Failure, mock, storage, loading/error dan UI dipertahankan. Use case akan bernilai jika ada aturan aplikasi atau orkestrasi beberapa repository yang nyata, bukan sekadar membungkus setiap method.

Hasil verifikasi perubahan: analyzer bersih dan **24 test lulus**. Grep membuktikan Domain/Failure bebas package dan layer luar, entity bebas mapping, Presentation bebas data mentah, widget bebas constructor repository dan formatting tanggal mentah. Kontrol positif memastikan kontrak, implementasi, model dan wiring benar-benar ada pada path yang diuji.

## Refactoring dan testing

Pola Domain/Data diterapkan pada notifikasi pengumuman yang sudah ada. Use case RegisterDevice mengatur pengambilan dan sinkronisasi token, termasuk force refresh. Formatting tanggal dan parsing route dipindahkan ke core/format.dart.

Analyzer bersih dan **32 tes lulus**. [Catatan singkat dan screenshot](campus_notify/docs/refactoring/README.md).
