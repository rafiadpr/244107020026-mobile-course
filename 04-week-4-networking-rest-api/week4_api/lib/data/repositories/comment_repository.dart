import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository yang bertanggung jawab atas semua komunikasi
/// dengan endpoint /comments di JSONPlaceholder.
///
/// Pola Repository memisahkan logika akses data (HTTP, cache, DB)
/// dari logika bisnis/UI, sehingga mudah diganti atau di-mock saat testing.
class CommentRepository {
  /// Konstruktor menerima instance Dio dari luar (dependency injection)
  /// agar mudah di-mock pada unit test tanpa melakukan HTTP sungguhan.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil daftar komentar untuk [postId] tertentu.
  ///
  /// Endpoint: GET /comments?postId={postId}
  ///
  /// Timeout 10 detik didefinisikan per-request menggunakan [Options]
  /// sehingga lebih fleksibel daripada hanya mengandalkan timeout
  /// global di [BaseOptions]. Jika server tidak merespons dalam
  /// 10 detik, Dio akan melempar [DioExceptionType.receiveTimeout].
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId}, // ?postId=1
      options: Options(
        // receiveTimeout khusus request ini: 10 detik.
        receiveTimeout: const Duration(seconds: 10),
        // sendTimeout: waktu tunggu saat mengirim request body.
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    // response.data bisa null jika server mengembalikan body kosong.
    // Gunakan ?? [] sebagai fallback aman.
    final data = response.data ?? [];

    // whereType<Map<String, dynamic>>() menyaring elemen yang bukan
    // Map (misalnya null atau tipe tidak terduga) sebelum parsing.
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
