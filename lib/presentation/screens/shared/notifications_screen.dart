import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/repositories/care_repository.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    required this.user,
    required this.services,
    super.key,
  });
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('Notifications')),
    body: StreamBuilder<List<UserNotification>>(
      stream: services.care.watchNotifications(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error is CareFailure
                  ? (snapshot.error! as CareFailure).message
                  : 'Notifications could not be loaded.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data!;
        if (notifications.isEmpty) {
          return const Center(child: Text('You are all caught up.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = notifications[index];
            return ListTile(
              onTap: item.readAt == null
                  ? () => services.care.markNotificationRead(
                      uid: user.uid,
                      notificationId: item.id,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              tileColor: item.readAt == null
                  ? AppColors.peachLight
                  : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.border),
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(_icon(item.type)),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${item.body}\n${DateFormat.yMMMd().add_jm().format(item.createdAt)}',
              ),
              isThreeLine: true,
              trailing: item.readAt == null
                  ? const Badge()
                  : const Icon(Icons.done_rounded, size: 18),
            );
          },
        );
      },
    ),
  );

  IconData _icon(String type) => switch (type) {
    'appointment' => Icons.calendar_month_outlined,
    'vaccination' => Icons.vaccines_outlined,
    'adoption' => Icons.favorite_outline_rounded,
    'blog' => Icons.auto_stories_outlined,
    _ => Icons.notifications_none_rounded,
  };
}
