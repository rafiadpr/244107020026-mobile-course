import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/device_registration.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/register_device.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.fail = false});
  final bool fail;
  final calls = <String>[];

  @override
  Future<DeviceTokenResult> getToken() async {
    calls.add('get');
    return fail
        ? (token: null, failure: const LocalFailure('Gagal membaca token'))
        : (token: 'test-token', failure: null);
  }

  @override
  Future<DeviceRegistrationResult> syncToken(String token) async {
    calls.add('sync');
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
    return (failure: null);
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
    final repo = FakeAnnouncementRepository(fail: true);
    final result = await RegisterDevice(repo)();
    expect(result.failure, isA<LocalFailure>());
    expect(result.registration, isNull);
    expect(repo.calls, ['get']);
  });

  test('Force refresh menghapus token sebelum registrasi ulang', () async {
    final repo = FakeAnnouncementRepository();
    await RegisterDevice(repo)(forceRefresh: true);
    expect(repo.calls, ['delete', 'get', 'sync']);
  });
}
