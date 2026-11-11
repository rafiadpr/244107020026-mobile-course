# Temuan performa

Campus Notify berasal dari pertemuan 7. Daftar ditambahkan dengan 120 pengumuman lokal. Pengujian dilakukan pada halaman daftar di Windows dalam mode `profile`.

Skenario pengujian meliputi membuka daftar, scroll, membuka detail lalu kembali lima kali, dan refresh. Kedua versi memakai data dan ukuran jendela yang sama.

| Masalah | Perbaikan |
| --- | --- |
| `List.generate` membuat seluruh widget item sekaligus | Menggunakan `ListView.builder` |
| `setState` saat refresh membangun ulang halaman | Menggunakan `ValueListenableBuilder` untuk label penghitung |
| Item dan detail bercampur dalam satu method; widget statis dibuat kembali | Memisahkan widget item dan detail, lalu menambahkan `const` pada bagian statis |

| Pengukuran | Sebelum | Sesudah |
| --- | --- | --- |
| Rata-rata UI/build | 0,482 ms | 0,428 ms |
| Rata-rata raster | 1,777 ms | 1,665 ms |
| Rata-rata durasi frame | 3,267 ms | 3,092 ms |
| Frame merah pada acuan 60 FPS | 1 | 1 |

Masing-masing versi menghasilkan 657 frame. Rata-rata durasi frame turun sekitar 5,3%, tetapi jumlah frame lambat masih sama. Hasil ini berasal dari satu pengukuran per versi.

Pada buffer timeline, `GPURasterizer::Draw` memiliki durasi tertinggi. Buffer memiliki batas, sehingga hanya sebagian event yang tersimpan.

Setelah lima kali membuka dan menutup detail, jumlah state daftar tetap satu. Pada versi sesudah optimasi, jumlah objek halaman detail kembali menjadi nol. Tidak terlihat penumpukan halaman pada skenario ini. `ValueNotifier` dibersihkan melalui `dispose()`.

Total heap ikut meningkat karena data pengujian dan timeline tersimpan dalam memori. Kenaikan ini belum cukup untuk membuktikan kebocoran memori.

Bukti tampilan tersedia pada [sebelum optimasi](../screenshots/before-profile.png) dan [sesudah optimasi](../screenshots/after-profile.png). 