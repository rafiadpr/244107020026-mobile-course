import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../../../data/api_errors.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_auth_data_source.dart';
import '../datasources/token_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.source, required this.store});

  final MockAuthDataSource source;
  final TokenStore store;

  @override
  Future<AuthSessionResult> login({
    required String email,
    required String password,
  }) async {
    final model = await _login(email, password);
    if (model.failure != null || model.session == null) return model;
    try {
      await store.save(
        access: model.session!.access,
        refresh: model.session!.refresh,
      );
      return model;
    } on Exception {
      return (
        session: null,
        failure: const LocalFailure('Gagal menyimpan sesi. Silakan coba lagi.'),
      );
    }
  }

  Future<AuthSessionResult> _login(String email, String password) async {
    try {
      final model = await source.login(email: email, password: password);
      return (session: model.toEntity(), failure: null);
    } on Exception catch (error) {
      return (session: null, failure: _remoteFailure(error));
    }
  }

  @override
  Future<RefreshResult> refresh(String refreshToken) async {
    try {
      final access = await source.refresh(refreshToken);
      return (access: access, failure: null);
    } on Exception catch (error) {
      return (access: null, failure: _remoteFailure(error));
    }
  }

  @override
  Future<AuthStatusResult> getAuthStatus() async {
    try {
      final access = await store.readAccess();
      return (authenticated: access != null, failure: null);
    } on Exception {
      return (
        authenticated: false,
        failure: const LocalFailure('Gagal membaca sesi. Silakan coba lagi.'),
      );
    }
  }

  @override
  Future<LogoutResult> logout() async {
    try {
      await store.clear();
      return (failure: null);
    } on Exception {
      return (
        failure: const LocalFailure('Gagal menghapus sesi. Silakan coba lagi.'),
      );
    }
  }

  NetworkFailure _remoteFailure(Exception error) =>
      NetworkFailure(switch (error) {
        InvalidCredentialsException() => 'Email atau kata sandi tidak valid',
        MissingRefreshTokenException() => 'Refresh token hilang',
        DioException() => ApiErrors.mapDioError(error),
        _ => 'Gagal memproses autentikasi. Silakan coba lagi.',
      }, statusCode: error is DioException ? error.response?.statusCode : null);
}
