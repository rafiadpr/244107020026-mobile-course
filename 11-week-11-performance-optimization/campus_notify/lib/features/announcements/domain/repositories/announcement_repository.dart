import '../../../../core/failures.dart';
import '../entities/device_registration.dart';

typedef NotificationResult = ({Failure? failure});
typedef DeviceTokenResult = ({String? token, Failure? failure});
typedef DeviceRegistrationResult = ({
  DeviceRegistration? registration,
  Failure? failure,
});

/// Operasi notifikasi pengumuman yang sudah ada; bukan API daftar pengumuman.
abstract class AnnouncementRepository {
  Future<NotificationResult> initialize();
  Future<DeviceTokenResult> getToken();
  Future<DeviceRegistrationResult> syncToken(String token);
  Future<NotificationResult> deleteToken();
  Future<NotificationResult> changeCampusTopic(bool subscribe);
  Stream<DeviceTokenResult> get tokenRefreshes;
  NotificationResult listenNotifications(
    void Function(String route) onNavigate,
  );
  Future<NotificationResult> handleInitialNotification(
    void Function(String route) onNavigate,
  );
}
