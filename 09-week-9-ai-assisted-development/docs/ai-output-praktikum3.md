**Reproduksi dan akar masalah**

Pada versi kode yang Anda jelaskan:

```dart
final normalizedQuery = query.toLowerCase();
```

Input `'  beasiswa  '` tetap memiliki spasi di kedua ujungnya. Pencocokan `contains()` kemudian mencari teks beserta spasinya sehingga menghasilkan `[]`, padahal pengumuman berjudul **Pendaftaran Beasiswa Kampus** memiliki ID `'43'`.

Query `'   '` juga tidak dianggap kosong karena masih mengandung spasi. Akibatnya, pencarian melakukan filter dan menghasilkan daftar kosong.

Langkah reproduksinya adalah membuka daftar, memasukkan `'  beasiswa  '`, lalu membandingkan hasil dengan pencarian `'beasiswa'`. Reproduksi versi bermasalah tersebut tidak dijalankan ulang pada pemeriksaan ini karena file saat ini sudah mengandung perbaikan.

**Perbandingan sebelum dan sesudah**

```dart
// Sebelum
final normalizedQuery = query.toLowerCase();

// Sesudah — sudah tersedia pada file saat ini
final normalizedQuery = query.trim().toLowerCase();
```

| Input | Sebelum | Sesudah |
|---|---|---|
| `'  beasiswa  '` | `[]` | Pengumuman ID `'43'` |
| `'   '` | `[]` | Seluruh pengumuman |
| `'BEASISWA'` | Pengumuman ID `'43'` | Pengumuman ID `'43'` |

`trim()` menghapus spasi tepi sebelum pemeriksaan query kosong dan pencocokan judul. Perbaikan ini mempertahankan pencarian tanpa membedakan huruf besar/kecil.

**Pemeriksaan arsitektur dan refactor**

| Bagian | Hasil pemeriksaan |
|---|---|
| Widget | Mengelola input, daftar, empty state, dan navigasi |
| Notifier | Menyimpan query dan hasil; memanggil use case |
| Use case domain | Melakukan normalisasi dan filter judul dengan Dart murni |
| Kontrak repository | Mendefinisikan pengambilan daftar, terpisah dari repository FCM |
| Implementasi repository | Menyediakan data contoh lokal |

Tidak ditemukan pelanggaran pembagian tanggung jawab pada fitur pencarian. Tidak ada fungsi produksi fitur pencarian yang melebihi 40 baris; fungsi `build` terpanjang berjumlah 21 baris. Fungsi `main()` pada test mengelompokkan beberapa test terpisah, sehingga tidak perlu dipecah sebagai fungsi produksi.

**Tidak dilakukan refactor**, karena tidak ditemukan masalah nyata yang memerlukannya. Seluruh test pembukti dan ekspektasinya dipertahankan.

**Hasil aktual perintah**

| Perintah | Hasil |
|---|---|
| `flutter test test/search_announcements_test.dart` | Exit `0`; **9 test lulus** |
| `flutter analyze` | Exit `0`; **No issues found!** |
| `dart format --set-exit-if-changed .` | Exit `1`; gagal menelusuri direktori artefak `build/firebase_core/.transforms/...` dengan `PathNotFoundException` |
| `dart format --set-exit-if-changed lib test` | Pemeriksaan lanjutan: exit `0`; **42 file diperiksa, 0 berubah** |
| `flutter test` | Exit `0`; **54 test lulus** |

Seluruh test lulus, termasuk test spasi tepi, query berisi spasi saja, pemulihan daftar, dan sumber data yang tidak berubah. Saat smoke test muncul log Firebase belum diinisialisasi, tetapi tidak menyebabkan kegagalan test.

Pemeriksaan format seluruh folder **belum berhasil** karena kendala direktori build; pemeriksaan langsung kode `lib` dan `test` berhasil. Screenshot `02-test-setelah-perbaikan.png` belum diambil. README, AI log, AI Challenge, dan refleksi tidak diubah.