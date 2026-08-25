import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/user_role.dart';
import '../adoption/shelter_operations_screen.dart';
import 'notifications_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({required this.user, required this.services, super.key});
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    if (user.role == UserRole.shelterAdmin) {
      return _ShelterInbox(user: user, services: services);
    }
    return _UserInbox(user: user, services: services);
  }
}

class _UserInbox extends StatelessWidget {
  const _UserInbox({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<UserNotification>>(
    stream: services.care.watchActivityNotifications(user),
    builder: (context, snapshot) {
      final updates = snapshot.data ?? const <UserNotification>[];
      return _InboxLayout(
        title: 'Secure updates',
        subtitle: 'Private care, appointment, and adoption activity.',
        empty: 'No secure updates yet.',
        children: updates
            .take(8)
            .map(
              (item) => _InboxTile(
                title: item.title,
                body: item.body,
                time: DateFormat.MMMd().add_jm().format(item.createdAt),
                unread: item.readAt == null,
              ),
            )
            .toList(),
        onOpenAll: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsScreen(user: user, services: services),
          ),
        ),
      );
    },
  );
}

class _ShelterInbox extends StatelessWidget {
  const _ShelterInbox({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<CommunityRequest>>(
    stream: services.care.watchContactMessages(user),
    builder: (context, snapshot) {
      final messages = snapshot.data ?? const <CommunityRequest>[];
      return _InboxLayout(
        title: 'Shelter inbox',
        subtitle: 'Private inquiries scoped to your shelter.',
        empty: 'No shelter inquiries yet.',
        children: messages
            .take(8)
            .map(
              (item) => _InboxTile(
                title: item.userName,
                body: item.message,
                time: DateFormat.MMMd().add_jm().format(item.createdAt),
                unread: item.status == 'pending',
              ),
            )
            .toList(),
        onOpenAll: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CommunityRequestsScreen(
              user: user,
              services: services,
              module: CommunityModule.contact,
            ),
          ),
        ),
      );
    },
  );
}

class _InboxLayout extends StatelessWidget {
  const _InboxLayout({
    required this.title,
    required this.subtitle,
    required this.empty,
    required this.children,
    required this.onOpenAll,
  });
  final String title;
  final String subtitle;
  final String empty;
  final List<Widget> children;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 6),
        Text(subtitle),
        const SizedBox(height: 22),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text(empty)),
          )
        else
          ...children,
        if (children.isNotEmpty)
          OutlinedButton(onPressed: onOpenAll, child: const Text('Open all')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Inbox data is visible only to authenticated participants.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
  final String title;
  final String body;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: unread ? AppColors.peachLight : AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.surface,
          child: Text(
            title.characters.first,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(time, style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}
