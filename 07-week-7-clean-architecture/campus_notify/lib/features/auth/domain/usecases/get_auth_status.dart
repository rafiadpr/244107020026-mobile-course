import '../repositories/auth_repository.dart';

class GetAuthStatus {
  const GetAuthStatus(this._repository);
  final AuthRepository _repository;

  Future<AuthStatusResult> call() => _repository.getAuthStatus();
}
