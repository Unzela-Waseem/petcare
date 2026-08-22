abstract interface class PushNotificationService {
  Future<void> startForUser(String uid);
  Future<void> stop();
}

class NoopPushNotificationService implements PushNotificationService {
  const NoopPushNotificationService();

  @override
  Future<void> startForUser(String uid) async {}

  @override
  Future<void> stop() async {}
}
