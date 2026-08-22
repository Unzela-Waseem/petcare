import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  @override
  Future<AppUser?> restoreSession() async => _currentUser;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!email.contains('@') || password.isEmpty) {
      throw const AuthFailure('Enter a valid email and password.');
    }
    return _currentUser = AppUser(
      uid: 'demo-owner',
      name: 'Jamie Parker',
      email: email.trim(),
      phone: '+1 555 010 2026',
      role: UserRole.petOwner,
      emailVerified: true,
    );
  }

  @override
  Future<AppUser> signInDemo(UserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final names = {
      UserRole.petOwner: 'Jamie Parker',
      UserRole.veterinarian: 'Dr. Maya Chen',
      UserRole.shelterAdmin: 'Alex Morgan',
    };
    return _currentUser = AppUser(
      uid: 'demo-${role.value}',
      name: names[role]!,
      email: '${role.value}@pawfectcare.demo',
      phone: '+1 555 010 2026',
      role: role,
      emailVerified: true,
    );
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _currentUser = AppUser(
      uid: 'demo-${role.value}',
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      emailVerified: true,
    );
  }

  @override
  Future<AppUser> refreshVerification() async {
    if (_currentUser == null) {
      throw const AuthFailure(
        'Your session has expired. Please sign in again.',
      );
    }
    return _currentUser!;
  }

  @override
  Future<void> resendVerification() async {}

  @override
  Future<void> resetPassword(String email) async {
    if (!email.contains('@')) throw const AuthFailure('Enter a valid email.');
  }

  @override
  Future<void> signOut() async => _currentUser = null;
}
