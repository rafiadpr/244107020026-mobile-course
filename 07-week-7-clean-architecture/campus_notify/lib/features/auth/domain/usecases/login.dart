import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);
  final AuthRepository _repository;

  Future<AuthSessionResult> call({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);
}
