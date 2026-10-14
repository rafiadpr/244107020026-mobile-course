import '../../domain/entities/device_registration.dart';

class DeviceRegistrationModel extends DeviceRegistration {
  const DeviceRegistrationModel({
    required super.token,
    required super.isSynced,
    required super.updatedAt,
    required this.platform,
  });
  final String platform;

  Map<String, Object?> toMap() => {
    'fcm_token': token,
    'platform': platform,
    'updated_at': updatedAt.toIso8601String(),
  };

  DeviceRegistration toEntity() => DeviceRegistration(
    token: token,
    isSynced: isSynced,
    updatedAt: updatedAt,
  );
}
