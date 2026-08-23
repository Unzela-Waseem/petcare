import '../models/app_user.dart';
import 'care_repository.dart';

abstract interface class ReminderService {
  Future<void> initialize();

  Future<void> start({required AppUser user, required CareRepository care});

  Future<void> stop();
}

class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start({
    required AppUser user,
    required CareRepository care,
  }) async {}

  @override
  Future<void> stop() async {}
}
