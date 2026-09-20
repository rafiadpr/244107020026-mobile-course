/// Model data untuk satu komentar dari endpoint
/// GET /comments?postId={id} pada JSONPlaceholder.
///
/// Setiap field menggunakan pola null-safe:
///   (json['key'] as Type?)?.convert() ?? defaultValue
/// sehingga jika field hilang atau bertipe null di JSON,
/// program tidak crash melainkan menggunakan nilai default.
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// ID post yang dikomentar (relasi ke Post.id).
  final int postId;

  /// ID unik komentar ini.
  final int id;

  /// Nama pemberi komentar.
  final String name;

  /// Alamat email pemberi komentar.
  final String email;

  /// Isi teks komentar.
  final String body;

  /// Factory constructor: mengubah Map JSON → objek Comment.
  ///
  /// Pola `(json['key'] as num?)?.toInt() ?? 0` dipakai untuk
  /// field numerik karena JSON kadang mengirim angka sebagai
  /// `int` atau `double`; cast ke `num` lalu `.toInt()` aman
  /// untuk keduanya. Jika field tidak ada, fallback ke 0.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Serialisasi objek → Map JSON (berguna untuk testing / caching).
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
