import '../models/app_user.dart';
import '../models/user_role.dart';

abstract interface class AuthRepository {
  Future<AppUser?> restoreSession();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signInDemo(UserRole role);

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  });

  Future<AppUser> refreshVerification();

  Future<void> resendVerification();

  Future<void> resetPassword(String email);

  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
