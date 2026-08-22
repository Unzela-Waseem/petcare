import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.emailVerified,
    this.accountStatus = 'active',
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final bool emailVerified;
  final String accountStatus;
  final String? photoUrl;

  AppUser copyWith({bool? emailVerified, String? accountStatus}) => AppUser(
    uid: uid,
    name: name,
    email: email,
    phone: phone,
    role: role,
    emailVerified: emailVerified ?? this.emailVerified,
    accountStatus: accountStatus ?? this.accountStatus,
    photoUrl: photoUrl,
  );
}
