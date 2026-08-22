import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/user_role.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({required this.role, super.key});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final messages = switch (role) {
      UserRole.petOwner => const [
        ('Dr. Maya Chen', 'Luna’s appointment is confirmed.', '9:42'),
        (
          'Happy Tails Shelter',
          'We received your adoption request.',
          'Yesterday',
        ),
      ],
      UserRole.veterinarian => const [
        ('Jamie Parker', 'Luna has been doing well this week.', '9:42'),
        ('Clinic desk', 'Your afternoon schedule was updated.', 'Yesterday'),
      ],
      UserRole.shelterAdmin => const [
        ('Jamie Parker', 'Could I arrange a visit with Coco?', '9:42'),
        ('Aisha Khan', 'I can volunteer on Saturdays.', 'Yesterday'),
      ],
    };
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: [
          Text('Messages', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          const Text('Private conversations connected to your care activity.'),
          const SizedBox(height: 22),
          ...messages.map(
            (message) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.peachLight,
                    child: Text(
                      message.$1.characters.first,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.$1,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          message.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(message.$3, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                    'Messages are visible only to authenticated participants.',
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
}
