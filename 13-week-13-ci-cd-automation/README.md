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

# Praktikum 3 : Menjalankan dan mengevaluasi pipeline

1. Push commit [4a089cc](https://github.com/rafiadpr/244107020026-mobile-course/commit/4a089cc2c61c7ce1f7fa8b5d099d3c086b89e973) ke branch `feature/week13-ci-cd-automation` memicu [Flutter CI #4](https://github.com/rafiadpr/244107020026-mobile-course/actions/runs/45554616513).
2. Job `verify` berhasil dalam 6 menit 5 detik. Artefak `android-builds` berisi `app-release.apk` dan `app-release.aab`.

| Pemeriksaan | Hasil |
| --- | --- |
| Format Dart | Lulus |
| Analisis Flutter | Lulus |
| Tes Flutter dengan cakupan pengujian | Lulus |
| Build APK dan AAB | Keduanya berhasil |
| Unggah artefak | `android-builds` tersedia di bagian **Artifacts** |

![Hasil Flutter CI #4 dengan build APK, AAB, dan unggah artefak berhasil](screenshots/flutter_ci_run_4.png)
