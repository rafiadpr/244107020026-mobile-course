import '../../../../core/failures.dart';
import '../repositories/announcement_repository.dart';

/// Urutan registrasi lama, dipakai init, event refresh dan tombol debug.
class RegisterDevice {
  const RegisterDevice(this._repository);
  final AnnouncementRepository _repository;

  Future<DeviceRegistrationResult> call({
    String? token,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      final deleted = await _repository.deleteToken();
      if (deleted.failure != null) {
        return (registration: null, failure: deleted.failure);
      }
      token = null;
    }
    if (token == null) {
      final result = await _repository.getToken();
      if (result.failure != null) {
        return (registration: null, failure: result.failure);
      }
      token = result.token;
    }
    if (token == null || token.trim().isEmpty) {
      return (
        registration: null,
        failure: const LocalFailure(
          'Token FCM belum tersedia (Pastikan Firebase sudah dikonfigurasi).',
        ),
      );
    }
    return _repository.syncToken(token);
  }
}
