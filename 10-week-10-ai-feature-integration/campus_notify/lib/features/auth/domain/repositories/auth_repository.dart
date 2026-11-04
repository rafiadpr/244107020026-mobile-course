import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

typedef AuthSessionResult = ({AuthSession? session, Failure? failure});
typedef RefreshResult = ({String? access, Failure? failure});
typedef AuthStatusResult = ({bool authenticated, Failure? failure});
typedef LogoutResult = ({Failure? failure});

abstract class AuthRepository {
  Future<AuthSessionResult> login({
    required String email,
    required String password,
  });
  Future<RefreshResult> refresh(String refreshToken);
  Future<AuthStatusResult> getAuthStatus();
  Future<LogoutResult> logout();
}
