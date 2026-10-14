# Modul 7 — Clean Architecture

## Praktikum 1: Audit layer project lama

Proyek dasar tetap **campus_notify (Modul 6)**. Contoh notes/SQLite pada gambar diterapkan sebagai pola pemisahan tanggung jawab, bukan sebagai fitur baru. Fitur yang dipisahkan pada Praktikum 2 adalah auth: login mock, refresh token, pemeriksaan sesi dan logout yang sudah berjalan.

### Snapshot sebelum refactor

Snapshot sudah tersedia: `ddb8197 chore: snapshot before clean architecture`.

Sintaks pengingat, dijalankan dari root repository:
```powershell
git status --short
git add -- 07-week-7-clean-architecture/campus_notify
git diff --cached --stat
git commit -m "chore: snapshot before clean architecture"
```
Pilih file yang akan di-stage; jangan memasukkan perubahan Modul 6 lain secara otomatis. Audit/refactor ini tidak membuat commit baru.

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

### Struktur target dan struktur auth yang sudah diterapkan

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

Tidak ada folder notes baru. Entity auth memakai access/refresh yang sudah ada, bukan field catatan atau data pengumuman fiktif. Fondasi fetch announcements dari implementasi sebelumnya telah dihapus beserta test-nya karena tidak berasal dari fitur lama.

## Praktikum 2: Domain dan Data per fitur auth

### Entity murni dan Failure

AuthSession hanya memiliki field final access/refresh dan constructor; tidak mengimpor Flutter, package eksternal, atau mapping. Core Failure tetap sealed dengan LocalFailure dan NetworkFailure (status HTTP opsional). Failure tidak membawa objek exception SDK ke Domain.

### Kontrak abstract dengan Dart Records

```dart
typedef AuthSessionResult = ({AuthSession? session, Failure? failure});
typedef RefreshResult = ({String? access, Failure? failure});
typedef AuthStatusResult = ({bool authenticated, Failure? failure});
typedef LogoutResult = ({Failure? failure});

abstract class AuthRepository {
  Future<AuthSessionResult> login({
    required String email,
    required String password,
  });
  Future<RefreshResult> refresh(String refreshToken);
  Future<AuthStatusResult> getAuthStatus();
  Future<LogoutResult> logout();
}
```

Sukses login/refresh: nilai hasil non-null dan failure null. Gagal: hasil null dan failure non-null. Status sesi false dengan failure null berarti belum login; false dengan failure non-null berarti pembacaan storage gagal.

### Model dan implementasi Data

AuthSessionModel extends AuthSession dan menyediakan fromMap, toMap serta toEntity. Mapping hanya berada di Data; repository mengembalikan AuthSession baru, bukan model. Map memakai key access/refresh dan menolak tipe selain String.

AuthRepositoryImpl menerima MockAuthDataSource dan TokenStore melalui constructor. Try-catch mengubah kegagalan sumber auth/refresh menjadi NetworkFailure dan kegagalan save/read/clear storage menjadi LocalFailure. Simulasi auth Modul 6 tetap menggunakan delay 500/300 ms, aturan email/password lama dan token mock lama. Tidak ditambahkan API Firebase, SQLite atau endpoint baru.

Penyimpanan token saat login, pemeriksaan status dan penghapusan token saat logout berada di repository Data. Interceptor tetap membaca token melalui adapter Data dan menyimpan token hasil refresh; flag isRetry mempertahankan batas retry satu kali. Record refresh gagal ditangani tanpa mengirim exception sumber ke presentation.

### Use case dan penyesuaian pemanggil

Login, Logout dan GetAuthStatus masing-masing memiliki satu operasi melalui call(). Refresh dipanggil langsung melalui kontrak repository oleh interceptor Data; tidak ditambahkan use case yang tidak dibutuhkan. Gambar mengizinkan akses repository langsung untuk operasi sederhana.

Notifier presentation memanggil use case dan menerjemahkan Failure.message menjadi AsyncError untuk UI. SDK exception tidak melewati kontrak Domain. Validator form dan state loading tetap dipertahankan.

Arah dependency:
```text
Presentation -> use case -> kontrak repository Domain
Data -> Domain (implementasi kontrak dan konversi entity)
provider fitur auth -> Data + Domain (wiring fitur)
core/providers.dart dan messaging/providers.dart -> dependency bersama
```

Domain hanya mengimpor file Dart lokal dan core Failure. Shared providers bukan bagian Domain.

### Verifikasi

```powershell
flutter analyze --no-pub
flutter test --no-pub
rg -n 'package:|fromMap|toMap|jsonDecode|/data/|/presentation/' lib/features/auth/domain lib/core/failures.dart
```

Tes memeriksa mapping entity/model, login dan penyimpanan token, Record gagal, read/save/clear storage gagal, pemulihan state notifier, status sesi/logout, refresh gagal, refresh sukses dan batas retry satu kali, parsing rute serta smoke test. Mock HTTP tidak mengirim request internet. Hasil akhir Praktikum 2: analyzer bersih dan seluruh 20 test lulus. Pemeriksaan regex Domain/Failure tidak menemukan import package, mapping atau dependency Data/Presentation. Verifikasi lanjutan dicatat pada Praktikum 3 di bawah.

## Praktikum 3: Presentation, DI dan verifikasi

### 1. Wiring fitur dengan Riverpod

`lib/features/auth/presentation/providers/auth_provider.dart` adalah satu-satunya tempat perakitan repository dan use case auth. Provider repository bertipe kontrak Domain; implementasi Data berada di balik kontrak tersebut. Import Data dalam file wiring ini sesuai pengecualian pada contoh praktikum, bukan alasan untuk mengimpor Data di halaman.

```dart
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    source: ref.watch(authDataSourceProvider),
    store: ref.watch(tokenStoreProvider),
  ),
);

final loginProvider = Provider<Login>(
  (ref) => Login(ref.watch(authRepositoryProvider)),
);
```

`core/providers.dart` hanya merakit dependency bersama (TokenStore dan clock). `messaging/providers.dart` merakit HTTP client/PushService yang sudah ada. Notifier memanggil use case dan menerjemahkan Failure menjadi AsyncValue error; tidak melakukan secure-storage/HTTP/JSON secara langsung. Ini memisahkan wiring fitur dari infrastruktur bersama tanpa dependency melingkar antara shared storage dan state auth.

### 2. Halaman membaca state dan meneruskan aksi

- LoginPage membaca authStateProvider, memakai isLoading untuk spinner/tombol disabled, dan menampilkan pesan error dari state. Pengguna mencoba login kembali melalui tombol Masuk yang sama; tidak ditambahkan layar atau fitur baru. Validator form dan UI lama dipertahankan.
- AnnouncementPage dipindahkan ke features/announcements/presentation/pages dan menjadi ConsumerWidget. Halaman membaca announcementDateLabelProvider; tanggal tidak lagi dihitung tiga kali di build. Clock dapat dioverride saat pengujian. Konten tetap contoh statis, tanpa fetch/repository baru.
- DebugTokenPage membaca maskedToken dan lastUpdatedLabel dari FcmState. Konversi waktu lokal berada pada formatter presentation; halaman tidak memanggil toLocal. Clipboard dan navigasi tetap merupakan interaksi UI.
- Formatter di core/presentation/formatters/date_labels.dart mempertahankan format teks lama. Domain tidak menerima tanggung jawab formatting UI.

### 3. Verifikasi dependency rule

Jalankan dari campus_notify. Semua pencarian berikut menghasilkan **nol temuan**; exit code 1 dari rg berarti tidak ada kecocokan, bukan error alat.

```powershell
# Presentation steril dari akses data mentah
$presentationPaths = @(
  'lib/pages',
  'lib/providers',
  'lib/features/auth/presentation',
  'lib/features/announcements/presentation'
)
rg -n -g '*.dart' 'Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode' $presentationPaths

# Domain/Failure steril dari package, mapping dan dependency layer luar
rg -n -g '*.dart' '^import.*package:|fromMap|toMap|jsonDecode|/data/|/presentation/' lib/features/auth/domain lib/core/failures.dart

# Tidak ada formatting tanggal mentah di halaman/widget
rg -n -g '**/pages/**' -g '**/widgets/**' 'DateFormat|jsonDecode|DateTime\.now\(|\.toLocal\(|\.toIso8601String' lib

flutter analyze --no-pub
flutter test --no-pub
```

Hasil: analyzer **No issues found**, seluruh **24 test lulus**. Empat test baru pada test/presentation_test.dart menggunakan override kontrak repository/clock/state untuk loading, error, retry, label tanggal dan masking FCM tanpa plugin nyata. Retry otomatis Riverpod dinonaktifkan hanya pada fixture tes status error agar backoff tidak memperpanjang tes; perilaku aplikasi tidak diubah.

### 4. Verifikasi perangkat dan screenshot

Uji dilakukan pada Redmi Note 9 Pro (Android 12), 14 Oktober 2026. Versi sebelum Praktikum 3 direkam terlebih dahulu. Sesi versi sesudah refactor berlangsung 21:25–21:31 WIB, lebih dari lima menit untuk auth: sesi tersimpan, logout, validasi email, koreksi input, login ulang dan navigasi. Label/bounds Login, Home dan Pengumuman identik sebelum/sesudah; pemeriksaan visual screenshot juga menunjukkan layout tetap sama.

Bukti dan hasil lengkap: [screenshots/README.md](campus_notify/screenshots/README.md).

| Halaman | Sebelum | Sesudah |
| --- | --- | --- |
| Login | [Screenshot](campus_notify/screenshots/praktikum3_before_login.png) | [Screenshot](campus_notify/screenshots/praktikum3_after_login.png) |
| Home | [Screenshot](campus_notify/screenshots/praktikum3_before_home.png) | [Screenshot](campus_notify/screenshots/praktikum3_after_home.png) |
| Pengumuman | [Screenshot](campus_notify/screenshots/praktikum3_before_announcement.png) | [Screenshot](campus_notify/screenshots/praktikum3_after_announcement.png) |

Scope auth dan Presentation Praktikum 3 telah terverifikasi. FCM mengeluarkan `FCM Registration failed!` sejak baseline, sehingga pengiriman notifikasi/topik/token refresh perangkat belum dinyatakan lolos end-to-end. Konfigurasi Firebase dan logika fallback service lama tidak diubah. Refactor kontrak internal FCM dan pemisahan mapper ApiErrors tetap menjadi item audit di luar fitur auth yang dipilih, bukan perubahan fitur diam-diam.

