import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/datasources/mock_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

// Satu tempat wiring auth. Notifier memakai kontrak Domain untuk operasi sederhana.
final authDataSourceProvider = Provider<MockAuthDataSource>(
  (ref) => MockAuthDataSource(),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    source: ref.watch(authDataSourceProvider),
    store: ref.watch(tokenStoreProvider),
  ),
);

extension AuthStateMessage on AsyncValue<bool> {
  String? get errorMessage => hasError ? error.toString() : null;
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final result = await ref.watch(authRepositoryProvider).getAuthStatus();
    if (result.failure != null) {
      // Riverpod mengubah pesan presentation ini menjadi AsyncError.
      throw result.failure!.message;
    }
    return result.authenticated;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    if (result.failure != null) {
      state = AsyncError(result.failure!.message, StackTrace.current);
    } else {
      state = const AsyncData(true);
    }
  }

  Future<void> logout() async {
    final result = await ref.read(authRepositoryProvider).logout();
    if (result.failure != null) {
      state = AsyncError(result.failure!.message, StackTrace.current);
    } else {
      ref.invalidateSelf();
    }
  }
}
