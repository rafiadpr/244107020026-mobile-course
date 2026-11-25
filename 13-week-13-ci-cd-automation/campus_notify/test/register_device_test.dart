import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/device_registration.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/register_device.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({
    this.token = 'test-token',
    this.getFailure,
    this.deleteFailure,
    this.syncFailure,
  });
  final String? token;
  final Failure? getFailure;
  final Failure? deleteFailure;
  final Failure? syncFailure;
  final calls = <String>[];

  @override
  Future<DeviceTokenResult> getToken() async {
    calls.add('get');
    return (token: getFailure == null ? token : null, failure: getFailure);
  }

  @override
  Future<DeviceRegistrationResult> syncToken(String token) async {
    calls.add('sync');
    if (syncFailure != null) {
      return (registration: null, failure: syncFailure);
    }
    return (
      registration: DeviceRegistration(
        token: token,
        isSynced: true,
        updatedAt: DateTime(2026, 10, 15),
      ),
      failure: null,
    );
  }

  @override
  Future<NotificationResult> deleteToken() async {
    calls.add('delete');
    return (failure: deleteFailure);
  }

  // Operasi ini tidak dipakai oleh RegisterDevice.
  @override
  Future<NotificationResult> initialize() => throw UnimplementedError();
  @override
  Future<NotificationResult> changeCampusTopic(bool subscribe) =>
      throw UnimplementedError();
  @override
  Stream<DeviceTokenResult> get tokenRefreshes => throw UnimplementedError();
  @override
  NotificationResult listenNotifications(void Function(String) onNavigate) =>
      throw UnimplementedError();
  @override
  Future<NotificationResult> handleInitialNotification(
    void Function(String) onNavigate,
  ) => throw UnimplementedError();
}

void main() {
  test('Registrasi mengambil token lalu menyinkronkannya', () async {
    final repo = FakeAnnouncementRepository();
    final result = await RegisterDevice(repo)();
    expect(result.failure, isNull);
    expect(result.registration!.token, 'test-token');
    expect(repo.calls, ['get', 'sync']);
  });

  test('Failure diteruskan dan sinkronisasi tidak dijalankan', () async {
    const failure = LocalFailure('Gagal membaca token');
    final repo = FakeAnnouncementRepository(getFailure: failure);
    final result = await RegisterDevice(repo)();
    expect(result.failure, same(failure));
    expect(result.registration, isNull);
    expect(repo.calls, ['get']);
  });

  test('Force refresh menghapus token sebelum registrasi ulang', () async {
    final repo = FakeAnnouncementRepository();
    final result = await RegisterDevice(repo)(
      token: 'old-token',
      forceRefresh: true,
    );
    expect(result.failure, isNull);
    expect(result.registration!.token, 'test-token');
    expect(repo.calls, ['delete', 'get', 'sync']);
  });

  for (final token in ['', '   ']) {
    test('Token eksplisit "$token" ditolak tanpa membaca atau sync', () async {
      final repo = FakeAnnouncementRepository();
      final result = await RegisterDevice(repo)(token: token);
      expect(result.failure, isA<LocalFailure>());
      expect(result.registration, isNull);
      expect(repo.calls, isEmpty);
    });
  }

  for (final token in <String?>[null, '', '   ']) {
    test('Token "$token" dari getToken ditolak tanpa sync', () async {
      final repo = FakeAnnouncementRepository(token: token);
      final result = await RegisterDevice(repo)();
      expect(result.failure, isA<LocalFailure>());
      expect(result.registration, isNull);
      expect(repo.calls, ['get']);
    });
  }

  test('Token eksplisit valid dipakai utuh tanpa getToken', () async {
    final repo = FakeAnnouncementRepository();
    const token = '  explicit-token  ';
    final result = await RegisterDevice(repo)(token: token);
    expect(result.failure, isNull);
    expect(result.registration!.token, token);
    expect(repo.calls, ['sync']);
  });

  test(
    'Delete gagal menghentikan force refresh sebelum get dan sync',
    () async {
      const failure = LocalFailure('Gagal menghapus token');
      final repo = FakeAnnouncementRepository(deleteFailure: failure);
      final result = await RegisterDevice(repo)(
        token: 'old-token',
        forceRefresh: true,
      );
      expect(result.failure, same(failure));
      expect(result.registration, isNull);
      expect(repo.calls, ['delete']);
    },
  );

  test('Failure sync diteruskan tanpa registration', () async {
    const failure = NetworkFailure('Gagal sinkronisasi', statusCode: 500);
    final repo = FakeAnnouncementRepository(syncFailure: failure);
    final result = await RegisterDevice(repo)();
    expect(result.failure, same(failure));
    expect(result.registration, isNull);
    expect(repo.calls, ['get', 'sync']);
  });

  test('Force refresh berhenti jika get gagal setelah delete', () async {
    const failure = LocalFailure('Gagal membaca token setelah delete');
    final repo = FakeAnnouncementRepository(getFailure: failure);
    final result = await RegisterDevice(repo)(
      token: 'old-token',
      forceRefresh: true,
    );
    expect(result.failure, same(failure));
    expect(result.registration, isNull);
    expect(repo.calls, ['delete', 'get']);
  });

  for (final token in ['', '   ']) {
    test('Force refresh menolak token baru "$token"', () async {
      final repo = FakeAnnouncementRepository(token: token);
      final result = await RegisterDevice(repo)(
        token: 'old-token',
        forceRefresh: true,
      );
      expect(result.failure, isA<LocalFailure>());
      expect(result.registration, isNull);
      expect(repo.calls, ['delete', 'get']);
    });
  }
}
