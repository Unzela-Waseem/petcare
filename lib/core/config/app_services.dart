import '../../data/repositories/demo_care_repository.dart';
import '../../data/services/firebase_media_storage_service.dart';
import '../../data/services/shared_preferences_offline_article_service.dart';
import '../../domain/repositories/care_repository.dart';
import '../../domain/repositories/media_storage_service.dart';
import '../../domain/repositories/offline_article_service.dart';
import '../../domain/repositories/reminder_service.dart';

class AppServices {
  const AppServices({
    required this.care,
    required this.media,
    required this.offlineArticles,
    required this.reminders,
  });

  factory AppServices.demo() => AppServices(
    care: DemoCareRepository(),
    media: const DemoMediaStorageService(),
    offlineArticles: SharedPreferencesOfflineArticleService(),
    reminders: const NoopReminderService(),
  );

  final CareRepository care;
  final MediaStorageService media;
  final OfflineArticleService offlineArticles;
  final ReminderService reminders;
}
