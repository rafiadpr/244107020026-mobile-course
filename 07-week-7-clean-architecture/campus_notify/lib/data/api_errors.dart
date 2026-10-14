import 'package:dio/dio.dart';

/// Helper terpusat untuk memetakan DioException menjadi pesan user-friendly
class ApiErrors {
  static String mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server timeout. Silakan periksa jaringan internet Anda.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Permintaan tidak valid (400). Periksa kembali data yang dikirim.';
          case 401:
            return 'Sesi Anda telah berakhir atau token tidak valid. Silakan login kembali.';
          case 403:
            return 'Akses ditolak (403). Anda tidak memiliki izin untuk halaman ini.';
          case 404:
            return 'Data atau layanan tidak ditemukan (404).';
          case 500:
          case 502:
          case 503:
            return 'Terjadi kendala pada server kampus ($statusCode). Silakan coba lagi nanti.';
          default:
            return 'Terjadi kesalahan server dengan kode status: $statusCode.';
        }

      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda atau server sedang offline.';

      case DioExceptionType.cancel:
        return 'Permintaan jaringan dibatalkan.';

      case DioExceptionType.badCertificate:
        return 'Sertifikat keamanan server tidak valid.';

      case DioExceptionType.unknown:
      default:
        final msg = error.message ?? '';
        if (msg.contains('SocketException') || msg.contains('Network is unreachable')) {
          return 'Tidak ada koneksi internet (Offline).';
        }
        return 'Terjadi kesalahan jaringan yang tidak terduga. Silakan coba lagi.';
    }
  }

  /// Ekstraksi pesan ramah pengguna dari Object error umum
  static String getMessage(Object error) {
    if (error is DioException) {
      return mapDioError(error);
    }
    return error.toString().replaceFirst(RegExp(r'^Exception: '), '');
  }
}
