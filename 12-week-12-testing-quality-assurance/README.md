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

# Praktikum 3 : Pengujian widget

1. Membuat halaman daftar tugas

Halaman di [lib/task_page.dart](testing_lab/lib/task_page.dart)

Aplikasi menampilkan kolom `Judul tugas`, tombol `Simpan tugas`, dan daftar tugas. Jika belum ada data, halaman menampilkan pesan kosong beserta cara menambah tugas.

2. Menghubungkan halaman dengan repository

Penyimpanan di [lib/memory_task_repository.dart](testing_lab/lib/memory_task_repository.dart)

3. Menguji tampilan dan interaksi

Pengujian di [test/task_page_test.dart](testing_lab/test/task_page_test.dart)

4. Skenario pengujian

| Skenario | Hasil yang diharapkan |
| --- | --- |
| Halaman dibuka tanpa tugas | Judul halaman, form, tombol simpan, dan pesan kosong tampil |
| Repository memiliki data | Tugas yang sudah ada tampil di daftar |
| Judul kosong atau hanya spasi | Pesan validasi tampil dan repository tidak menyimpan tugas |
| Judul valid disimpan | Tugas muncul tanpa spasi awal dan akhir, data lama tetap ada, dan kolom input kosong kembali |
| Data sedang dimuat atau disimpan | Indikator loading tampil saat memuat; tombol dan input dinonaktifkan saat menyimpan agar tugas tidak terkirim dua kali |
| Gagal memuat data | Pesan gagal dan tombol `Coba lagi` tampil; data bisa dimuat setelah kondisi diperbaiki |
| Gagal menyimpan tugas | Input tetap berisi judul, tugas belum masuk daftar, dan penyimpanan bisa dicoba lagi |

5. Temuan

Pesan daftar kosong perlu dibedakan dari pesan gagal memuat data. Saat penyimpanan gagal, judul tetap berada di kolom input agar tidak perlu diketik ulang. Tombol simpan dinonaktifkan selama penyimpanan untuk mencegah tugas yang sama terkirim dua kali.

# Praktikum 4 : Pengujian integrasi dan regresi

1. Menguji alur utama aplikasi

Pengujian di [integration_test/app_test.dart](testing_lab/integration_test/app_test.dart)

| Skenario | Hasil yang diharapkan |
| --- | --- |
| Aplikasi dibuka | Halaman daftar tugas tampil dan daftar masih kosong |
| Judul hanya berisi spasi | Pesan validasi tampil dan tidak ada tugas yang ditambahkan |
| Judul `Baca materi` disimpan dengan spasi di awal dan akhir | Tugas tampil tanpa spasi tambahan, pesan validasi hilang, dan kolom input kosong kembali |
| Tugas kedua disimpan | Kedua tugas tampil di daftar dan tugas pertama tetap ada |

2. Menambahkan pengujian regresi

Pengujian regresi ditambahkan di [test/task_page_test.dart](testing_lab/test/task_page_test.dart) dengan nama `regresi: input kosong setelah menyimpan tidak menambah tugas`.

Setelah satu tugas berhasil disimpan, tombol simpan ditekan lagi saat input kosong. Pengujian juga mencoba input yang hanya berisi spasi. Kedua kondisi harus menampilkan pesan validasi, sedangkan daftar dan catatan penyimpanan pada fake tetap berisi satu tugas.

3. Temuan

Pengujian integrasi memeriksa alur dari input pengguna sampai tugas tampil di daftar. Pengujian regresi menjaga agar aturan validasi tetap berlaku setelah tugas pertama disimpan dan kolom input dibersihkan.

# Praktikum 5 : Menyusun test suite untuk fitur tugas

1. Mencatat perilaku fitur

| Skenario | Jenis pengujian | Hasil yang diharapkan |
| --- | --- | --- |
| Judul berisi teks | Unit dan widget | Judul diterima dan tugas dapat disimpan |
| Judul kosong atau hanya spasi | Unit dan widget | Judul ditolak dan tidak ada tugas baru |
| Judul satu karakter | Unit | Judul tetap diterima karena sudah berisi teks |
| Daftar tugas kosong | Unit dan widget | Hasil berupa daftar kosong dan pesan kosong tampil |
| Repository gagal memuat atau menyimpan | Unit dan widget | Error diteruskan, pesan gagal tampil, dan penyimpanan yang gagal tidak menambah tugas |
| Tugas berhasil disimpan | Widget | Tugas tampil dan kolom input dibersihkan |
| Tombol simpan ditekan saat proses berjalan | Widget | Tombol dinonaktifkan dan tugas hanya disimpan satu kali |
| Dua tugas ditambahkan melalui aplikasi | Integrasi | Kedua tugas tampil di daftar |

2. Mengelompokkan pengujian logika

Validasi judul di [test/is_valid_task_title_test.dart](testing_lab/test/is_valid_task_title_test.dart)

Service di [test/task_service_test.dart](testing_lab/test/task_service_test.dart)

Repository memori di [test/memory_task_repository_test.dart](testing_lab/test/memory_task_repository_test.dart)

3. Menguji dependensi dengan fake

Fake di [test/fakes/fake_task_repository.dart](testing_lab/test/fakes/fake_task_repository.dart)

Setiap pengujian membuat repository sendiri agar data tidak terbawa ke pengujian lain

4. Menguji tampilan dan interaksi

Pengujian UI di [test/task_page_test.dart](testing_lab/test/task_page_test.dart)

Skenarionya mencakup tampilan awal, data kosong, input tidak valid, penyimpanan berhasil, loading, dan pesan gagal

5. Menguji alur utama

Pengujian integrasi di [integration_test/app_test.dart](testing_lab/integration_test/app_test.dart)

Alur utama menjalankan aplikasi, menolak input spasi, lalu menyimpan dua tugas

# Pengujian

1. Flutter test

Hasil praktikum 1: enam pengujian unit validasi judul tugas lulus.

![Hasil flutter test](screenshots/flutter_test_praktikum1.png)

2. Flutter analyze

Hasil analisis praktikum 1 tidak menemukan masalah.

![Hasil flutter analyze](screenshots/flutter_analyze_praktikum1.png)
