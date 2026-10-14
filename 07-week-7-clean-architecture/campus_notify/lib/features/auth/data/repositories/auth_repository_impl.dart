import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
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
    } on Exception catch (error) {
      return (session: null, failure: LocalFailure(_message(error)));
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
    } on Exception catch (error) {
      return (authenticated: false, failure: LocalFailure(_message(error)));
    }
  }

  @override
  Future<LogoutResult> logout() async {
    try {
      await store.clear();
      return (failure: null);
    } on Exception catch (error) {
      return (failure: LocalFailure(_message(error)));
    }
  }

  NetworkFailure _remoteFailure(Exception error) => NetworkFailure(
    _message(error),
    statusCode: error is DioException ? error.response?.statusCode : null,
  );

  String _message(Exception error) =>
      error.toString().replaceFirst(RegExp(r'^Exception: '), '');
}
