import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({firebase.FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? firebase.FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Future<AppUser?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _loadProfile(_auth.currentUser!);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _loadProfile(credential.user!);
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthFailure(_safeAuthMessage(error.code));
    }
  }

  @override
  Future<AppUser> signInDemo(UserRole role) => throw const AuthFailure(
    'Demo access is disabled in Firebase production mode.',
  );

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': role.value,
        'accountStatus': 'pendingEmailVerification',
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await user.sendEmailVerification();
      return AppUser(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        emailVerified: false,
        accountStatus: 'pendingEmailVerification',
      );
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthFailure(_safeAuthMessage(error.code));
    }
  }

  @override
  Future<AppUser> refreshVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Your session has expired.');
    await user.reload();
    return _loadProfile(_auth.currentUser!);
  }

  @override
  Future<void> resendVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Your session has expired.');
    await user.sendEmailVerification();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthFailure(_safeAuthMessage(error.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _loadProfile(firebase.User user) async {
    final snapshot = await _db.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    if (data == null) {
      await _auth.signOut();
      throw const AuthFailure('Your account profile is incomplete.');
    }
    final role = UserRole.tryParse(data['role'] as String?);
    if (role == null) {
      await _auth.signOut();
      throw const AuthFailure('This account has an unsupported role.');
    }
    var status = data['accountStatus'] as String? ?? 'disabled';
    if (status == 'disabled') {
      await _auth.signOut();
      throw const AuthFailure('This account is disabled.');
    }
    if (user.emailVerified && status == 'pendingEmailVerification') {
      await snapshot.reference.update({
        'accountStatus': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      status = 'active';
    }
    return AppUser(
      uid: user.uid,
      name: data['name'] as String? ?? user.displayName ?? 'PawfectCare user',
      email: data['email'] as String? ?? user.email ?? '',
      phone: data['phone'] as String? ?? '',
      role: role,
      emailVerified: user.emailVerified,
      accountStatus: status,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  String _safeAuthMessage(String code) => switch (code) {
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'The email or password is incorrect.',
    'email-already-in-use' => 'An account already uses this email.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Choose a stronger password.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'Check your connection and try again.',
    _ => 'Authentication could not be completed.',
  };
}
