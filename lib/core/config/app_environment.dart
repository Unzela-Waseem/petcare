abstract final class AppEnvironment {
  static const usesFirebase = bool.fromEnvironment(
    'USE_FIREBASE',
    defaultValue: false,
  );

  static const usesFirebaseStorage = bool.fromEnvironment(
    'USE_FIREBASE_STORAGE',
    defaultValue: false,
  );

  static const usesFirebasePush = bool.fromEnvironment(
    'USE_FIREBASE_PUSH',
    defaultValue: false,
  );

  static const appName = 'PawfectCare';
  static const fcmWebVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
  static bool get isDemo => !usesFirebase;
}
