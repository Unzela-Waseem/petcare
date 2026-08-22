import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStore {
  Future<bool> hasCompletedOnboarding();
  Future<void> completeOnboarding();
  Future<void> clearSensitiveState();
}

class SecureSessionStore implements SessionStore {
  const SecureSessionStore();

  static const _onboardingKey = 'pawfectcare.onboarding.complete';
  static const _storage = FlutterSecureStorage();

  @override
  Future<bool> hasCompletedOnboarding() async =>
      await _storage.read(key: _onboardingKey) == 'true';

  @override
  Future<void> completeOnboarding() =>
      _storage.write(key: _onboardingKey, value: 'true');

  @override
  Future<void> clearSensitiveState() async {
    final onboarding = await hasCompletedOnboarding();
    await _storage.deleteAll();
    if (onboarding) await completeOnboarding();
  }
}

class MemorySessionStore implements SessionStore {
  MemorySessionStore({this.onboardingComplete = false});

  bool onboardingComplete;

  @override
  Future<void> clearSensitiveState() async {}

  @override
  Future<void> completeOnboarding() async => onboardingComplete = true;

  @override
  Future<bool> hasCompletedOnboarding() async => onboardingComplete;
}
