# AI Prompt Challenge
## A. Prompt Desain: GridView vs. LayoutBuilder + Column
* Versi GridView:
Responsivitas: Ringkas ditulis karena cukup mengubah crossAxisCount. Namun, GridView membatasi dimensi kartu lewat childAspectRatio yang statis. Jika ukuran font sistem diperbesar oleh pengguna (fitur accessibility text scaling), teks di dalam GridView sangat rentan terpotong (text clipped).
Aksesibilitas: Pembaca layar mengidentifikasi grid sebagai tabel/koleksi berindeks, yang kadang kurang natural untuk alur kartu dasbor vertikal.

* Versi LayoutBuilder + Column/Row (Dipilih):
Responsivitas: Komponen kartu membungkus konten berdasarkan tinggi intrinsik (Card menyesuaikan teks di dalamnya). Saat font membesar, kartu meregang secara dinamis tanpa overflow.
Aksesibilitas: Navigasi TalkBack mengalir runtut dari atas ke bawah (linear reading order), ideal untuk dasbor status.

##B. Prompt Penguatan Konsep: Kapan Expanded Menyebabkan Overflow?
Expanded di dalam Row memaksa anak mengisi ruang horisontal yang tersisa.

Penyebab kegagalan (Overflow):

Menaruh Row berisikan Expanded di dalam widget scroll horisontal (SingleChildScrollView(scrollDirection: Axis.horizontal)). Di sini, lebar parent bernilai tak hingga (double.infinity). Expanded bingung menentukan lebar dan melempar error:

"BoxConstraints forces an infinite width."

Isi teks di dalam Row yang tidak dibungkus Expanded melebihi batas layar, sementara elemen lain di-Expanded tanpa menyisakan ruang minimal.

Contoh gagal & perbaikan:

Dart
// GAGAL: crash bila di dalam SingleChildScrollView horizontal
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      Expanded(child: Text('Teks Panjang...')), // Error infinite width
    ],
  ),
);

// PERBAIKAN: Berikan batasan pasti atau gunakan Container/SizedBox
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      SizedBox(width: 250, child: Text('Teks Panjang...')),
    ],
  ),
);
C. Verification Prompt (Audit Mandiri Rekomendasi)
Responsif di bawah 600px: Terjamin, karena tata letak beralih ke 1 kolom dengan Column di dalam SingleChildScrollView.

Aksesibilitas: Terjaga lewat Semantics(container: true, excludeSemantics: true, label: ...) sehingga TalkBack membaca konteks utuh.

Ketersediaan Widget: Semua widget (Scaffold, LayoutBuilder, Row, Column, Expanded, Container, Card, Semantics) merupakan widget inti stabil Flutter.