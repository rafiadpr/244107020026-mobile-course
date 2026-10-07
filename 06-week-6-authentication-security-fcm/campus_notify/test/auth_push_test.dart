import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:campus_notify/routes.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/providers/auth_provider.dart';

/// Fake in-memory TokenStore untuk pengujian unit test tanpa native platform
class FakeTokenStore implements TokenStore {
  String? access;
  String? refresh;
  bool isCleared = false;

  FakeTokenStore({this.access, this.refresh});

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
    isCleared = false;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    isCleared = true;
  }
}

/// Fake AuthRepository yang sengaja gagal pada refresh untuk menguji session expire
class FailingAuthRepository extends AuthRepository {
  @override
  Future<String> refresh(String refreshToken) async {
    throw Exception('Refresh token expired or revoked');
  }
}

/// Mock HttpClientAdapter yang mensimulasikan respons 401 Unauthorized
class Mock401Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('Unauthorized', 401);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('1. Unit Test Pure Function: routeFromMessage', () {
    test('Mengembalikan AppRoutes.home jika payload null atau kosong', () {
      expect(routeFromMessage(null), AppRoutes.home);
      expect(routeFromMessage({}), AppRoutes.home);
    });

    test('Memperbaiki leading slash jika hilang pada payload route', () {
      final payload = {'route': 'pengumuman/3'};
      expect(routeFromMessage(payload), '/pengumuman/3');
    });

    test('Mempertahankan route yang sudah diawali slash', () {
      final payload = {'route': '/pengumuman/10'};
      expect(routeFromMessage(payload), '/pengumuman/10');
    });

    test('Mengekstrak payload spesifik pengumuman berdasarkan key id', () {
      final payload = {'id': '42'};
      expect(routeFromMessage(payload), '/pengumuman/42');
    });

    test('Mengutamakan key route dibandingkan key id jika keduanya ada', () {
      final payload = {'route': '/custom/page', 'id': '99'};
      expect(routeFromMessage(payload), '/custom/page');
    });
  });

  group('2. Unit Test Auth Provider dengan FakeTokenStore', () {
    test('AuthNotifier membaca status authenticated (true) jika token ada di store', () async {
      final fakeStore = FakeTokenStore(
        access: 'mock-access-token-123',
        refresh: 'mock-refresh-token-123',
      );

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
        ],
      );
      addTearDown(container.dispose);

      final authState = await container.read(authStateProvider.future);
      expect(authState, isTrue);
    });

    test('AuthNotifier membaca status unauthenticated (false) jika token kosong', () async {
      final fakeStore = FakeTokenStore(access: null, refresh: null);

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
        ],
      );
      addTearDown(container.dispose);

      final authState = await container.read(authStateProvider.future);
      expect(authState, isFalse);
    });

    test('Logout membersihkan token di store dan mengubah state ke false', () async {
      final fakeStore = FakeTokenStore(
        access: 'mock-access-token',
        refresh: 'mock-refresh-token',
      );

      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(fakeStore),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(authStateProvider.future), isTrue);

      // Panggil logout
      await container.read(authStateProvider.notifier).logout();

      expect(fakeStore.isCleared, isTrue);
      expect(fakeStore.access, isNull);
      expect(await container.read(authStateProvider.future), isFalse);
    });
  });

  group('3. Unit Test Token Refresh Gagal & Interceptor 401', () {
    test('Interceptor membersihkan TokenStore jika refresh token gagal / kedaluwarsa', () async {
      final fakeStore = FakeTokenStore(
        access: 'expired-access-token',
        refresh: 'expired-refresh-token',
      );
      final failingAuth = FailingAuthRepository();
      final dio = buildApiClient(fakeStore, failingAuth);
      dio.httpClientAdapter = Mock401Adapter();

      // Request yang akan menerima response 401 dan gagal refresh
      try {
        await dio.get('/protected-endpoint');
      } catch (_) {}

      // Verifikasi token store telah dibersihkan secara otomatis
      expect(fakeStore.isCleared, isTrue);
      expect(fakeStore.access, isNull);
      expect(fakeStore.refresh, isNull);
    });

    test('ApiErrors memetakan DioException 401 menjadi pesan sesi kedaluwarsa', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      final message = ApiErrors.mapDioError(dioException);
      expect(message, contains('Sesi Anda telah berakhir'));
    });

    test('ApiErrors memetakan DioException timeout menjadi pesan koneksi timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final message = ApiErrors.mapDioError(dioException);
      expect(message, contains('timeout'));
    });

    test('ApiErrors memetakan DioException connection error menjadi pesan offline', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final message = ApiErrors.mapDioError(dioException);
      expect(message, contains('Tidak dapat terhubung ke server'));
    });
  });
}
