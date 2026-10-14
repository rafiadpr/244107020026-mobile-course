import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/core/providers.dart';
import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:campus_notify/features/auth/data/models/auth_session_model.dart';
import 'package:campus_notify/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/usecases/login.dart';
import 'package:campus_notify/features/auth/domain/usecases/logout.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';

import 'auth_push_test.dart' show FakeTokenStore;

class FailingTokenStore extends FakeTokenStore {
  @override
  Future<void> save({required String access, required String refresh}) async {
    throw Exception('Storage unavailable');
  }

  @override
  Future<String?> readAccess() async => throw Exception('Storage unavailable');

  @override
  Future<void> clear() async => throw Exception('Storage unavailable');
}

class CountingAuthDataSource extends MockAuthDataSource {
  int refreshCount = 0;

  @override
  Future<String> refresh(String refreshToken) async {
    refreshCount++;
    return 'renewed-access';
  }
}

class RetryAdapter implements HttpClientAdapter {
  RetryAdapter({required this.failRetry});

  final bool failRetry;
  int requestCount = 0;
  String? retryAuthorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    if (requestCount > 1) {
      retryAuthorization = options.headers['Authorization'] as String?;
    }
    return ResponseBody.fromString(
      'response',
      requestCount == 1 || failRetry ? 401 : 200,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  for (final failRetry in [false, true]) {
    test('Interceptor refresh satu kali, retry gagal: $failRetry', () async {
      final store = FakeTokenStore(
        access: 'old-access',
        refresh: 'refresh-token',
      );
      final source = CountingAuthDataSource();
      final repository = AuthRepositoryImpl(source: source, store: store);
      final dio = buildApiClient(store, repository);
      final adapter = RetryAdapter(failRetry: failRetry);
      dio.httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      if (failRetry) {
        await expectLater(
          dio.get<Object?>('/test'),
          throwsA(isA<DioException>()),
        );
        expect(store.isCleared, isTrue);
      } else {
        expect((await dio.get<Object?>('/test')).statusCode, 200);
        expect(store.access, 'renewed-access');
        expect(store.refresh, 'refresh-token');
      }
      expect(source.refreshCount, 1);
      expect(adapter.requestCount, 2);
      expect(adapter.retryAuthorization, 'Bearer renewed-access');
    });
  }
  test('Model menjaga mapping token dan menghasilkan entity murni', () {
    final map = <String, Object?>{'access': 'a', 'refresh': 'r'};
    final model = AuthSessionModel.fromMap(map);
    expect(model.toMap(), map);
    expect(model.toEntity().runtimeType, AuthSession);
    expect(
      () => AuthSessionModel.fromMap({'access': 1}),
      throwsFormatException,
    );
  });

  test('Login use case memakai mock lama dan menyimpan kedua token', () async {
    final store = FakeTokenStore();
    final repository = AuthRepositoryImpl(
      source: MockAuthDataSource(),
      store: store,
    );
    final result = await Login(repository)(
      email: 'student@campus.ac.id',
      password: 'secret123',
    );
    expect(result.failure, isNull);
    expect(result.session!.runtimeType, AuthSession);
    expect(store.access, 'mock-access-for-student@campus.ac.id');
    expect(store.refresh, 'mock-refresh-for-student@campus.ac.id');
    expect((await repository.getAuthStatus()).authenticated, isTrue);
    expect((await Logout(repository)()).failure, isNull);
    expect(store.access, isNull);
  });

  test('Login invalid dan refresh invalid menjadi Record failure', () async {
    final store = FakeTokenStore();
    final repository = AuthRepositoryImpl(
      source: MockAuthDataSource(),
      store: store,
    );
    final result = await repository.login(email: 'invalid', password: 'short');
    expect(result.session, isNull);
    expect(result.failure, isA<NetworkFailure>());
    expect(result.failure!.message, 'Email atau kata sandi tidak valid');
    expect(store.access, isNull);
    final refresh = await repository.refresh('');
    expect(refresh.access, isNull);
    expect(refresh.failure, isA<NetworkFailure>());
  });

  test('Kegagalan save/read/clear storage menjadi LocalFailure', () async {
    final repository = AuthRepositoryImpl(
      source: MockAuthDataSource(),
      store: FailingTokenStore(),
    );
    final login = await repository.login(
      email: 'a@campus.ac.id',
      password: 'secret123',
    );
    expect(login.session, isNull);
    expect(login.failure, isA<LocalFailure>());
    final status = await repository.getAuthStatus();
    expect(status.authenticated, isFalse);
    expect(status.failure, isA<LocalFailure>());
    expect((await repository.logout()).failure, isA<LocalFailure>());
  });

  test('Notifier menerjemahkan Record gagal dan dapat login kembali', () async {
    final store = FakeTokenStore();
    final container = ProviderContainer(
      overrides: [tokenStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect(await container.read(authStateProvider.future), isFalse);
    final notifier = container.read(authStateProvider.notifier);
    await notifier.login('invalid', 'short');
    expect(container.read(authStateProvider).hasError, isTrue);
    expect(
      container.read(authStateProvider).error,
      'Email atau kata sandi tidak valid',
    );
    await notifier.login('a@campus.ac.id', 'secret123');
    expect(container.read(authStateProvider).value, isTrue);
  });
}
