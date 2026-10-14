import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.access, required super.refresh});

  factory AuthSessionModel.fromMap(Map<String, Object?> map) {
    final access = map['access'];
    final refresh = map['refresh'];
    if (access is! String || refresh is! String) {
      throw const FormatException('Format sesi tidak valid');
    }
    return AuthSessionModel(access: access, refresh: refresh);
  }

  Map<String, Object?> toMap() => {'access': access, 'refresh': refresh};

  AuthSession toEntity() => AuthSession(access: access, refresh: refresh);
}
