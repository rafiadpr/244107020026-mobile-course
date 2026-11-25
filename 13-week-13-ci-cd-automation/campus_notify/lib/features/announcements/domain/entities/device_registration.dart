class DeviceRegistration {
  const DeviceRegistration({
    required this.token,
    required this.isSynced,
    required this.updatedAt,
  });
  final String token;
  final bool isSynced;
  final DateTime updatedAt;
}
