# Refleksi Minggu 1

**1. Kapan native lebih tepat dipilih daripada cross-platform?**
Native lebih cocok kalau aplikasinya butuh performa yang maksimal atau perlu akses hardware hp yang spesifik (contohnya sensor khusus, bluetooth, kamera, dll).

**2. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?**
Di flutter, tampilan itu cuma cerminan data. Jadi kalau datanya berubah, flutter bakal otomatis rebuild widget tree yang kena efeknya saja.

**3. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?**
Karena biar gampang ngetrack history codingan, kalau ada bug, kita tinggal revert satu commit tanpa merusak fitur lain. kalau commitnya jelas juga nunjukin kalau cara kerjanya rapi dan terstruktur.