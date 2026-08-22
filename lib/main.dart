import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app/pawfect_care_app.dart';
import 'core/config/app_environment.dart';
import 'data/repositories/demo_auth_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/services/firebase_push_notification_service.dart';
import 'data/services/session_store.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/push_notification_service.dart';
import 'firebase_options.dart';
import 'presentation/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AuthRepository authRepository;
  late final PushNotificationService pushNotifications;
  if (AppEnvironment.usesFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    authRepository = FirebaseAuthRepository();
    pushNotifications = FirebasePushNotificationService();
  } else {
    authRepository = DemoAuthRepository();
    pushNotifications = const NoopPushNotificationService();
  }

  final controller = AuthController(
    authRepository: authRepository,
    sessionStore: const SecureSessionStore(),
    pushNotifications: pushNotifications,
  );
  runApp(PawfectCareApp(authController: controller));
}
