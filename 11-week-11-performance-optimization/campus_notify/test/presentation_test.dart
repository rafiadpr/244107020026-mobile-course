import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/core/providers.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/presentation/pages/login_page.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_notify/features/announcements/presentation/pages/announcement_page.dart';
import 'package:campus_notify/features/announcements/presentation/pages/debug_token_page.dart';
import 'package:campus_notify/features/announcements/presentation/providers/fcm_provider.dart';

class FakeAuthRepository implements AuthRepository {
  bool authenticated = false;
  Failure? statusFailure;
  Completer<AuthSessionResult>? pendingLogin;

  @override
  Future<AuthStatusResult> getAuthStatus() async =>
      (authenticated: authenticated, failure: statusFailure);

  @override
  Future<AuthSessionResult> login({
    required String email,
    required String password,
  }) async {
    if (pendingLogin != null) return pendingLogin!.future;
    authenticated = true;
    return (
      session: const AuthSession(
        access: 'test-access',
        refresh: 'test-refresh',
      ),
      failure: null,
    );
  }

  @override
  Future<RefreshResult> refresh(String refreshToken) async =>
      (access: 'renewed', failure: null);

  @override
  Future<LogoutResult> logout() async {
    authenticated = false;
    return (failure: null);
  }
}

class FakeFcmNotifier extends FcmNotifier {
  @override
  FcmState build() => FcmState(
    token: 'abcdefghijklmnop',
    isSynced: true,
    lastUpdatedAt: DateTime(2026, 10, 14, 21, 30),
  );
}

void main() {
  testWidgets(
    'Login menunjukkan loading, pesan gagal dan dapat dicoba kembali',
    (tester) async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pumpAndSettle();
      repository.pendingLogin = Completer<AuthSessionResult>();
      await tester.tap(find.text('Masuk'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      repository.pendingLogin!.complete((
        session: null,
        failure: const NetworkFailure('Login gagal'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Login gagal'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      repository.pendingLogin = null;
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      expect(container.read(authStateProvider).value, isTrue);
    },
  );

  test('Status error dapat dimuat ulang melalui invalidasi provider', () async {
    final repository = FakeAuthRepository()
      ..statusFailure = const LocalFailure('Storage gagal');
    final container = ProviderContainer(
      // Matikan backoff otomatis Riverpod pada tes kegagalan deterministik.
      retry: (_, _) => null,
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(authStateProvider.future),
      throwsA('Storage gagal'),
    );
    repository.statusFailure = null;
    container.invalidate(authStateProvider);
    expect(await container.read(authStateProvider.future), isFalse);
  });

  testWidgets('Pengumuman menampilkan tanggal dari state dan konten lama', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 14)),
        ],
        child: const MaterialApp(home: AnnouncementPage(id: '42')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pengumuman #42'), findsOneWidget);
    expect(find.text('Dipublikasikan: 14/10/2026'), findsOneWidget);
    expect(find.text('Kembali ke Halaman Utama'), findsOneWidget);
  });

  testWidgets('Debug FCM membaca label waktu dan masking dari state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fcmStateProvider.overrideWith(FakeFcmNotifier.new)],
        child: const MaterialApp(home: DebugTokenPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('abcdefghijkl... (Total: 16 chars)'), findsOneWidget);
    expect(
      find.text('Pembaruan Terakhir: 2026-10-14 21:30:00.000'),
      findsOneWidget,
    );
  });
}
