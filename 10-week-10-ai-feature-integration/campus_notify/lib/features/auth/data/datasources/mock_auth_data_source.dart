import '../models/auth_session_model.dart';

class InvalidCredentialsException implements Exception {}

class MissingRefreshTokenException implements Exception {}

/// Simulasi auth Modul 6; tidak mengganti mock dengan API/Firebase baru.
class MockAuthDataSource {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@') || password.length < 6) {
      throw InvalidCredentialsException();
    }
    return AuthSessionModel(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) throw MissingRefreshTokenException();
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
