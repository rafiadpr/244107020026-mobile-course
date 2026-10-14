import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';

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
