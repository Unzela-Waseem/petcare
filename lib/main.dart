import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app/pawfect_care_app.dart';
import 'core/config/app_environment.dart';
import 'core/config/app_services.dart';
import 'data/repositories/demo_auth_repository.dart';
import 'data/repositories/demo_care_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/firebase_care_repository.dart';
import 'data/services/cloudinary_media_storage_service.dart';
import 'data/services/firebase_media_storage_service.dart';
import 'data/services/firebase_push_notification_service.dart';
import 'data/services/hybrid_media_storage_service.dart';
import 'data/services/local_media_storage_service.dart';
import 'data/services/local_reminder_service.dart';
import 'data/services/session_store.dart';
import 'data/services/shared_preferences_offline_article_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/push_notification_service.dart';
import 'domain/repositories/reminder_service.dart';
import 'firebase_options.dart';
import 'presentation/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AuthRepository authRepository;
  late final PushNotificationService pushNotifications;
  late final ReminderService reminders;
  late final AppServices services;

  if (AppEnvironment.usesFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (AppEnvironment.usesFirebasePush) {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
    }

    authRepository = FirebaseAuthRepository();

    pushNotifications = AppEnvironment.usesFirebasePush
        ? FirebasePushNotificationService()
        : const NoopPushNotificationService();

    // Reminders are local notifications.
    // They should work independently of Firebase Push Notifications.
    reminders = LocalReminderService();

    await reminders.initialize();

    final localMedia = LocalMediaStorageService();

    services = AppServices(
      care: FirebaseCareRepository(),
      media: AppEnvironment.usesFirebaseStorage
          ? FirebaseMediaStorageService()
          : AppEnvironment.usesCloudinary
          ? HybridMediaStorageService(
              cloudImages: CloudinaryMediaStorageService(
                cloudName: AppEnvironment.cloudinaryCloudName,
                uploadPreset: AppEnvironment.cloudinaryUploadPreset,
              ),
              privateFiles: localMedia,
            )
          : localMedia,
      offlineArticles: SharedPreferencesOfflineArticleService(),
      reminders: reminders,
    );
  } else {
    authRepository = DemoAuthRepository();

    pushNotifications = const NoopPushNotificationService();

    services = AppServices(
      care: DemoCareRepository(),
      media: const DemoMediaStorageService(),
      offlineArticles: SharedPreferencesOfflineArticleService(),
      reminders: LocalReminderService(),
    );

    await services.reminders.initialize();
  }

  final controller = AuthController(
    authRepository: authRepository,
    sessionStore: const SecureSessionStore(),
    pushNotifications: pushNotifications,
  );

  runApp(
    PawfectCareApp(
      authController: controller,
      services: services,
    ),
  );
}