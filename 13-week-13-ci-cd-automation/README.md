# Praktikum 1 : Membuat workflow CI Flutter

1. [Campus Notify](campus_notify/) disalin dari proyek pertemuan 10 dan dipakai sebagai proyek Flutter untuk latihan CI.
2. [Workflow Flutter CI](../.github/workflows/flutter-ci.yml) dibuat di folder `.github/workflows` pada root repository.
3. Workflow berjalan saat ada push ke `main` atau `feature/week13-ci-cd-automation`, serta saat ada pull request ke `main`.

| Pemeriksaan | Fungsi |
| --- | --- |
| `flutter pub get` | Memasang dependensi proyek |
| `dart format --output=none --set-exit-if-changed .` | Memeriksa format kode Dart |
| `flutter analyze --fatal-infos` | Memeriksa masalah kode, termasuk temuan tingkat info |
| `flutter test --coverage` | Menjalankan tes dan mencatat cakupan pengujian |

Workflow memakai izin `contents: read` untuk membaca kode. Saat ada push baru ke branch yang sama, GitHub Actions membatalkan proses CI sebelumnya yang masih berjalan.

# Praktikum 2 : Membangun dan menyimpan APK dan AAB

1. [Workflow Flutter CI](../.github/workflows/flutter-ci.yml) membangun APK dan AAB setelah tes lulus.
2. Workflow memeriksa kedua berkas hasil build, lalu mengunggahnya sebagai satu artefak bernama `android-builds`.

| Perintah | Hasil |
| --- | --- |
| `flutter build apk --release` | `app-release.apk` untuk instalasi dan uji coba di perangkat Android |
| `flutter build appbundle --release` | `app-release.aab` untuk distribusi melalui Google Play |
