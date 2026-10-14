import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/datasources/mock_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_auth_status.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';

// Satu tempat wiring auth. State/UI mengonsumsi abstraksi dan use case ini.
final authDataSourceProvider = Provider<MockAuthDataSource>(
  (ref) => MockAuthDataSource(),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    source: ref.watch(authDataSourceProvider),
    store: ref.watch(tokenStoreProvider),
  ),
);
final loginProvider = Provider<Login>(
  (ref) => Login(ref.watch(authRepositoryProvider)),
);
final logoutProvider = Provider<Logout>(
  (ref) => Logout(ref.watch(authRepositoryProvider)),
);
final getAuthStatusProvider = Provider<GetAuthStatus>(
  (ref) => GetAuthStatus(ref.watch(authRepositoryProvider)),
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
    final result = await ref.watch(getAuthStatusProvider)();
    if (result.failure != null) {
      // Riverpod mengubah pesan presentation ini menjadi AsyncError.
      throw result.failure!.message;
    }
    return result.authenticated;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result = await ref.read(loginProvider)(
      email: email,
      password: password,
    );
    if (result.failure != null) {
      state = AsyncError(result.failure!.message, StackTrace.current);
    } else {
      state = const AsyncData(true);
    }
  }

  Future<void> logout() async {
    final result = await ref.read(logoutProvider)();
    if (result.failure != null) {
      state = AsyncError(result.failure!.message, StackTrace.current);
    } else {
      ref.invalidateSelf();
    }
  }
}
