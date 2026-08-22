import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/services/session_store.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/push_notification_service.dart';

enum AuthStage { initializing, onboarding, signedOut, verifying, authenticated }

class AuthController extends ChangeNotifier {
  factory AuthController({
    required AuthRepository authRepository,
    required SessionStore sessionStore,
    PushNotificationService pushNotifications =
        const NoopPushNotificationService(),
  }) => AuthController._(authRepository, sessionStore, pushNotifications);

  AuthController._(
    this._authRepository,
    this._sessionStore,
    this._pushNotifications,
  );

  final AuthRepository _authRepository;
  final SessionStore _sessionStore;
  final PushNotificationService _pushNotifications;

  AuthStage stage = AuthStage.initializing;
  AppUser? user;
  String? message;
  bool busy = false;

  Future<void> initialize() async {
    try {
      final onboardingComplete = await _sessionStore.hasCompletedOnboarding();
      if (!onboardingComplete) {
        stage = AuthStage.onboarding;
      } else {
        user = await _authRepository.restoreSession();
        _routeForUser();
      }
    } on Object {
      user = null;
      message = 'We could not restore your session. Please sign in again.';
      stage = AuthStage.signedOut;
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _sessionStore.completeOnboarding();
    stage = AuthStage.signedOut;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) =>
      _runAuth(() => _authRepository.signIn(email: email, password: password));

  Future<bool> signInDemo(UserRole role) =>
      _runAuth(() => _authRepository.signInDemo(role));

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) => _runAuth(
    () => _authRepository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    ),
  );

  Future<bool> _runAuth(Future<AppUser> Function() operation) async {
    busy = true;
    message = null;
    notifyListeners();
    try {
      user = await operation();
      _routeForUser();
      return true;
    } on AuthFailure catch (error) {
      message = error.message;
      stage = AuthStage.signedOut;
      return false;
    } on Object {
      message = 'Something went wrong. Please try again.';
      stage = AuthStage.signedOut;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> refreshVerification() async {
    busy = true;
    message = null;
    notifyListeners();
    try {
      user = await _authRepository.refreshVerification();
      _routeForUser();
      if (stage == AuthStage.verifying) {
        message = 'Your email is not verified yet.';
      }
      return stage == AuthStage.authenticated;
    } on AuthFailure catch (error) {
      message = error.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> resendVerification() async {
    try {
      await _authRepository.resendVerification();
      message = 'A new verification email has been sent.';
    } on AuthFailure catch (error) {
      message = error.message;
    }
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    busy = true;
    message = null;
    notifyListeners();
    try {
      await _authRepository.resetPassword(email);
      message = 'Password reset instructions have been sent.';
      return true;
    } on AuthFailure catch (error) {
      message = error.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    busy = true;
    notifyListeners();
    try {
      await _pushNotifications.stop();
      await _authRepository.signOut();
      await _sessionStore.clearSensitiveState();
    } finally {
      user = null;
      message = null;
      busy = false;
      stage = AuthStage.signedOut;
      notifyListeners();
    }
  }

  void _routeForUser() {
    if (user == null) {
      stage = AuthStage.signedOut;
    } else if (!user!.emailVerified) {
      stage = AuthStage.verifying;
    } else if (user!.accountStatus != 'active') {
      user = null;
      message = 'Your account is not active.';
      stage = AuthStage.signedOut;
    } else {
      stage = AuthStage.authenticated;
      unawaited(_pushNotifications.startForUser(user!.uid));
    }
  }
}
