# Praktikum 1 : Pengujian unit dan kasus tepi

1. Menentukan jenis pengujian

| Jenis | Bagian yang diperiksa |
| --- | --- |
| Unit | Aturan validasi judul tugas dan hasil pemanggilan repository |
| Widget | Tampilan halaman, pesan validasi, dan interaksi tombol simpan |
| Integrasi | Alur pengguna mengisi judul, menyimpan tugas, lalu melihatnya di daftar |

2. Skenario pengujian

| Skenario | Contoh input | Hasil yang diharapkan |
| --- | --- | --- |
| Judul berisi teks | `'Belajar Flutter'` | Diterima |
| Judul memiliki spasi di awal dan akhir | `'  Baca materi  '` | Diterima |
| Judul hanya satu karakter | `'A'` | Diterima |
| Teks kosong | `''` | Ditolak |
| Judul hanya berisi spasi | `'   '` | Ditolak |
| Judul hanya berisi tab dan baris baru | `'\t\n'` | Ditolak |

Judul satu karakter menjadi kasus batas karena aturan hanya mengharuskan adanya teks. Spasi, tab, dan baris baru termasuk kasus tepi yang bisa terlihat terisi meskipun tidak memiliki judul.

3. Membuat fungsi validasi

kode di [lib/is_valid_task_title.dart](testing_lab/lib/is_valid_task_title.dart)

4. Menulis pengujian dengan Arrange, Act, Assert

test ada di [test/is_valid_task_title_test.dart](testing_lab/test/is_valid_task_title_test.dart)

Setiap pengujian menggunakan pola berikut:

- Arrange: siapkan judul pada variabel `title`.
- Act: panggil `isValidTaskTitle(title)` dan simpan hasilnya pada `result`.
- Assert: periksa `result` dengan `expect`, menggunakan `isTrue` atau `isFalse`.

5. Temuan

Pemeriksaan `isNotEmpty` saja masih menerima input yang hanya berisi spasi. Penggunaan `trim()` membuat input tersebut ditolak. Pengujian juga memastikan judul yang benar tetap diterima walaupun memiliki spasi di awal dan akhir.

# Praktikum 2 : Menguji kode asinkron dan dependensi

1. Memisahkan kontrak sumber data

Kontrak di [lib/task_repository.dart](testing_lab/lib/task_repository.dart)

Service di [lib/task_service.dart](testing_lab/lib/task_service.dart)

2. Membuat fake repository

Fake ada di [test/fakes/fake_task_repository.dart](testing_lab/test/fakes/fake_task_repository.dart)

3. Menguji hasil berhasil, kosong, dan gagal

Pengujian ada di [test/task_service_test.dart](testing_lab/test/task_service_test.dart)

| Skenario | Kondisi repository | Hasil yang diharapkan |
| --- | --- | --- |
| Data berhasil dimuat | Berisi `Baca materi` dan `Kerjakan latihan` | Kedua tugas diterima sesuai urutan |
| Belum ada tugas | Daftar kosong | Hasil berupa daftar kosong |
| Gagal memuat tugas | Menghasilkan `Exception('Gagal memuat tugas')` | Error yang sama diteruskan ke pemanggil |

Pengujian berhasil dan kosong memakai `await` untuk menunggu data. Pengujian kegagalan memakai `await expectLater` dengan `throwsA(same(error))` untuk memastikan error tetap diteruskan.

4. Temuan

Daftar kosong dan kegagalan mengambil data perlu dibedakan. Daftar kosong berarti data berhasil diambil tetapi belum ada tugas. Jika repository gagal, service meneruskan error agar pemanggil dapat menangani kegagalan tersebut.

# Pengujian

1. Flutter test

Hasil praktikum 1: enam pengujian unit validasi judul tugas lulus.

![Hasil flutter test](screenshots/flutter_test_praktikum1.png)

2. Flutter analyze

Hasil analisis praktikum 1 tidak menemukan masalah.

![Hasil flutter analyze](screenshots/flutter_analyze_praktikum1.png)
