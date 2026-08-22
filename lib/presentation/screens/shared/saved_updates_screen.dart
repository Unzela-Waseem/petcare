import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/user_role.dart';

class SavedUpdatesScreen extends StatelessWidget {
  const SavedUpdatesScreen({required this.role, super.key});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final content = switch (role) {
      UserRole.petOwner => const (
        title: 'Your favorites',
        subtitle: 'Saved care tips, products, and adoption listings.',
        items: [
          'A calmer first vet visit',
          'Gentle grooming kit',
          'Coco · Labrador mix',
        ],
      ),
      UserRole.veterinarian => const (
        title: 'Clinical follow-ups',
        subtitle: 'Patients who need your attention next.',
        items: [
          'Luna · booster due',
          'Milo · allergy review',
          'Coco · post-op check',
        ],
      ),
      UserRole.shelterAdmin => const (
        title: 'Priority requests',
        subtitle: 'Applications and shelter work saved for review.',
        items: ['Jamie → Coco', 'Sam → Pepper', 'Weekend dog walking'],
      ),
    };
    final colors = [AppColors.peachLight, AppColors.mint, AppColors.lavender];
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: [
          Text(content.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(content.subtitle),
          const SizedBox(height: 24),
          ...List.generate(
            content.items.length,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.surface,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: AppColors.orangeDeep,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      content.items[index],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
