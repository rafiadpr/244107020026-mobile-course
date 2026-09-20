import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/comment.dart';
import 'providers.dart'; // dioProvider & friendlyErrorMessage sudah ada di sini
import 'repositories/comment_repository.dart';

// ---------------------------------------------------------------------------
// Provider: CommentRepository
// ---------------------------------------------------------------------------

/// Menyediakan satu instance [CommentRepository] ke seluruh widget tree.
///
/// Menggunakan [dioProvider] yang sudah ada agar Dio tidak dibuat ulang;
/// satu Dio bersama berarti satu connection pool & interceptor log.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

// ---------------------------------------------------------------------------
// AsyncNotifier: CommentListNotifier
// ---------------------------------------------------------------------------

/// Notifier yang mengelola state daftar komentar untuk satu postId.
///
/// Menggunakan [AsyncNotifier] (bukan [StateNotifier]) karena:
/// - build() bisa langsung async dan mengembalikan `Future<List<Comment>>`.
/// - Exception yang dilempar build() **otomatis** menjadi [AsyncError],
///   tanpa perlu try/catch manual di sekitar pemanggilan fetch.
///
/// [postId] dilewatkan sebagai argumen via [commentListProvider.call(postId)].
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  // postId diterima lewat constructor dan disimpan agar
  // build() dan refresh() bisa menggunakannya tanpa argumen.
  CommentListNotifier(this._postId);
  final int _postId;

  /// build() dipanggil Riverpod saat provider pertama kali dibaca
  /// atau setelah di-invalidate (misal: setelah refresh).
  ///
  /// Tidak perlu try/catch di sini — setiap exception yang terlempar
  /// dari repository akan ditangkap Riverpod dan disimpan sebagai
  /// state = AsyncError(error, stackTrace) secara otomatis.
  @override
  Future<List<Comment>> build() async {
    final repo = ref.watch(commentRepositoryProvider);
    return repo.fetchComments(_postId);
  }

  /// Memuat ulang komentar secara manual (misal: tombol "Coba lagi").
  ///
  /// Pola manual (set AsyncLoading → fetch → set AsyncData/AsyncError)
  /// dipakai di sini agar UI bisa membedakan "sedang refresh" vs
  /// "pertama kali loading" jika diperlukan.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(commentRepositoryProvider);
      state = AsyncData(await repo.fetchComments(_postId));
    } catch (e, st) {
      // st = StackTrace; disimpan agar debugger bisa menelusuri asal error.
      state = AsyncError(e, st);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider: commentListProvider (Family)
// ---------------------------------------------------------------------------

/// Provider keluarga (family) yang menerima [postId] sebagai argumen.
///
/// Cara pakai di widget:
///   final commentsAsync = ref.watch(commentListProvider(42));
///
/// Riverpod secara otomatis men-cache state per postId yang unik;
/// jika dua widget membaca postId yang sama, mereka berbagi state.
///
/// `retry: (_, __) => null` menonaktifkan retry otomatis Riverpod 3
/// sehingga error langsung final dan unit test tidak menggantung.
final commentListProvider = AsyncNotifierProvider.family<
    CommentListNotifier, List<Comment>, int>(
  (arg) => CommentListNotifier(arg),
  retry: (retryCount, error) => null,
);

// ---------------------------------------------------------------------------
// Fungsi pesan error ramah pengguna (khusus Comments)
// ---------------------------------------------------------------------------

/// Mengubah exception menjadi teks yang dapat ditampilkan ke pengguna.
///
/// Dibuat terpisah dari [friendlyErrorMessage] di providers.dart agar
/// komentar lebih spesifik konteksnya (misalnya bisa dikustomisasi
/// dengan nama resource "komentar" alih-alih pesan generik).
///
/// Kasus yang ditangani:
/// - **timeout** (connect / send / receive): jaringan lambat.
/// - **connectionError**: tidak ada internet / server tidak bisa dijangkau.
/// - **badResponse 404**: postId tidak ditemukan.
/// - **badResponse 500**: kesalahan internal server.
/// - **badResponse lainnya**: tampilkan kode HTTP.
/// - **error non-Dio**: pesan generik dengan toString().
String friendlyCommentError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      // Timeout: koneksi terlalu lama, kemungkinan jaringan buruk.
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa internet Anda lalu coba lagi.';

      // connectionError: tidak bisa reach server sama sekali.
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';

      // badResponse: server menjawab dengan HTTP error code.
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) {
          return 'Komentar tidak ditemukan. '
              'Pastikan postId yang Anda gunakan valid (404).';
        }
        if (code == 500) {
          return 'Server sedang bermasalah. Coba lagi beberapa saat (500).';
        }
        return 'Terjadi kesalahan dari server ($code). Coba lagi nanti.';

      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  // Error di luar Dio (misal: FormatException saat parsing).
  return 'Terjadi kesalahan tak terduga: $error';
}
