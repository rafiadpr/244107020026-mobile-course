import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../data/api_client.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import 'push_service.dart';

// Wiring infrastruktur bersama; tidak dipanggil langsung oleh halaman fitur.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
  ref.onDispose(() => dio.close());
  return dio;
});

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(dio: ref.watch(apiClientProvider)),
);
