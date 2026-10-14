import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../features/auth/data/datasources/mock_auth_data_source.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_auth_status.dart';
import '../features/auth/domain/usecases/login.dart';
import '../features/auth/domain/usecases/logout.dart';
import '../messaging/push_service.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
final authDataSourceProvider = Provider<MockAuthDataSource>((ref) => MockAuthDataSource());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
  source: ref.watch(authDataSourceProvider),
  store: ref.watch(tokenStoreProvider),
));
final loginProvider = Provider<Login>((ref) => Login(ref.watch(authRepositoryProvider)));
final logoutProvider = Provider<Logout>((ref) => Logout(ref.watch(authRepositoryProvider)));
final getAuthStatusProvider = Provider<GetAuthStatus>((ref) => GetAuthStatus(ref.watch(authRepositoryProvider)));
final apiClientProvider = Provider<Dio>((ref) {
  final dio = buildApiClient(ref.watch(tokenStoreProvider), ref.watch(authRepositoryProvider));
  ref.onDispose(() => dio.close());
  return dio;
});
final pushServiceProvider = Provider<PushService>((ref) => PushService(dio: ref.watch(apiClientProvider)));
