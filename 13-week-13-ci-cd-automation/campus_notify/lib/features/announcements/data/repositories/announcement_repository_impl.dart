import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../../../data/api_errors.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/push_service.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl({required this.service});

  final PushService service;

  Failure _failure(Exception error, String message) => error is DioException
      ? NetworkFailure(
          ApiErrors.mapDioError(error),
          statusCode: error.response?.statusCode,
        )
      : LocalFailure(message);

  @override
  Future<NotificationResult> initialize() async {
    try {
      await service.initialize();
      return (failure: null);
    } on Exception catch (error) {
      return (
        failure: _failure(
          error,
          'Gagal menyiapkan notifikasi. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Future<DeviceTokenResult> getToken() async {
    try {
      return (token: await service.getToken(), failure: null);
    } on Exception catch (error) {
      return (
        token: null,
        failure: _failure(
          error,
          'Token FCM belum tersedia (Pastikan Firebase sudah dikonfigurasi).',
        ),
      );
    }
  }

  @override
  Future<DeviceRegistrationResult> syncToken(String token) async {
    try {
      final model = await service.syncTokenToBackend(token);
      return (registration: model.toEntity(), failure: null);
    } on Exception catch (error) {
      return (
        registration: null,
        failure: _failure(
          error,
          'Gagal menyinkronkan token perangkat. Silakan coba lagi.',
        ),
      );
    }
  }

  @override
  Future<NotificationResult> deleteToken() async {
    try {
      await service.deleteToken();
      return (failure: null);
    } on Exception catch (error) {
      return (failure: _failure(error, 'Token gagal diperbarui.'));
    }
  }

  @override
  Future<NotificationResult> changeCampusTopic(bool subscribe) async {
    try {
      if (subscribe) {
        await service.subscribeCampusTopic();
      } else {
        await service.unsubscribeCampusTopic();
      }
      return (failure: null);
    } on Exception catch (error) {
      return (
        failure: _failure(error, 'Gagal mengubah topik. Silakan coba lagi.'),
      );
    }
  }

  @override
  Stream<DeviceTokenResult> get tokenRefreshes async* {
    try {
      await for (final token in service.onTokenRefresh) {
        yield (token: token, failure: null);
      }
    } on Exception catch (error) {
      yield (token: null, failure: _failure(error, 'Token gagal diperbarui.'));
    }
  }

  @override
  NotificationResult listenNotifications(
    void Function(String route) onNavigate,
  ) {
    try {
      service.listenForegroundAndBackground(onNavigate);
      return (failure: null);
    } on Exception catch (error) {
      return (failure: _failure(error, 'Gagal memantau notifikasi.'));
    }
  }

  @override
  Future<NotificationResult> handleInitialNotification(
    void Function(String route) onNavigate,
  ) async {
    try {
      await service.handleTerminated(onNavigate);
      return (failure: null);
    } on Exception catch (error) {
      return (failure: _failure(error, 'Gagal membuka notifikasi awal.'));
    }
  }
}
