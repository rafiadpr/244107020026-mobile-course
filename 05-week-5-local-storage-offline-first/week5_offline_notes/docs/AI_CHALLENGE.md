# AI Prompt Challenge & Verification

## 1. Prompt yang Digunakan
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream), type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan, beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.

## 2. Output AI & Tabel Perbandingan Final

**Perbandingan Local Storage di Flutter**

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
|---|---|---|---|---|
| **Kompleksitas Query** | Sangat Rendah (Key-Value) | Rendah (NoSQL/Box) | Tinggi (SQL native) | Sangat Tinggi (ORM/SQL) |
| **Kebutuhan Relasi** | Tidak Ada | Terbatas (HiveLink) | Sangat Baik (Foreign Key) | Sangat Baik (Type-safe rel) |
| **Reaktivitas (Stream)**| Tidak (Harus manual) | Ya (ValueListenable) | Terbatas (Butuh plugin) | Sangat Baik (Built-in) |
| **Type-Safety** | Rendah (Manual casting) | Sedang (TypeAdapter) | Rendah (Map<String, dynamic>) | Sangat Tinggi (Code gen) |
| **Ukuran Boilerplate** | Sangat Rendah | Sedang (Build_runner) | Sedang (SQL string, mapping) | Tinggi (Code gen, class) |
| **Kemudahan Testing** | Mudah (Mock/In-Memory) | Sedang | Sedang (In-Memory DB) | Mudah (Native Dart SQLite) |

### Rekomendasi Final

| Kebutuhan | Rekomendasi Storage | Alasan Utama |
|---|---|---|
| **Preferensi Tema** | **SharedPreferences** | Hanya menyimpan data kecil berformat *key-value* tunggal (boolean). Menggunakan database relasional untuk ini *overkill* dan lambat. |
| **Catatan (CRUD)** | **sqflite (SQLite)** | Data catatan terstruktur, sangat mudah diperluas di kemudian hari (misal jika ada relasi tag/kategori), dan optimal untuk melakukan kueri kompleks (seperti mencari notes yang `dirty == 1` dengan *limit* dan *order* tanpa harus me-load seluruh data ke *memory*). |

### Skema Tabel untuk 1000+ Catatan (SQLite)
```sql
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX idx_notes_updated ON notes(updated_at DESC);
```
*(Pembuatan indeks `idx_notes_updated` membantu sorting 1000+ catatan secara instan.)*

### Trade-off
- **SharedPreferences**: Cepat dan ringkas, tapi tidak bisa untuk query kompleks/skala besar.
- **Hive**: Sangat cepat karena semua data disimpan di memori (*in-memory*), tapi RAM bisa membengkak drastis jika catatan melebihi 1000+ dan mengandung gambar/teks panjang.
- **sqflite**: Query sangat powerful dan hemat memori, tapi query harus ditulis manual dengan *raw SQL* string yang rawan *typo*.
- **Drift**: Type-safe dan reaktif, tetapi *boilerplate*-nya masif karena menggunakan *code generation* (build_runner), yang memperlama proses *build* di project skala kecil.
