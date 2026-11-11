import 'package:dio/dio.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/data/datasources/token_store.dart';

Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          // [ANTI-LOOP]: Jika request ini adalah hasil retry, jangan coba refresh lagi
          if (e.requestOptions.extra['isRetry'] == true) {
            await store.clear();
            return handler.next(e);
          }

          final refresh = await store.readRefresh();
          if (refresh == null) {
            await store.clear();
            return handler.next(e);
          }

          try {
            // Trigger refresh token tepat SATU KALI
            final result = await auth.refresh(refresh);
            if (result.failure != null || result.access == null) {
              await store.clear();
              return handler.next(e);
            }
            final renewed = result.access!;
            await store.save(access: renewed, refresh: refresh);

            // Tandai request dengan flag isRetry sebelum mengirim ulang
            e.requestOptions.extra['isRetry'] = true;
            final retry = await dio.fetch(
              e.requestOptions..headers['Authorization'] = 'Bearer $renewed',
            );
            return handler.resolve(retry);
          } catch (_) {
            // Jika refresh token gagal/kedaluwarsa -> bersihkan sesi & paksa login ulang
            await store.clear();
            return handler.next(e);
          }
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}
