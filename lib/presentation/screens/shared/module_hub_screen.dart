import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/user_role.dart';
import '../pets/pet_detail_screen.dart';
import 'feature_catalog.dart';
import 'module_screen.dart';

class ModuleHubScreen extends StatelessWidget {
  const ModuleHubScreen({required this.role, super.key});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final features = FeatureCatalog.forRole(role);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: [
          Text(
            'Explore care',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Tools selected for your ${role.label.toLowerCase()} permissions.',
          ),
          const SizedBox(height: 22),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  final page = feature.title == 'My Pets'
                      ? const PetDetailScreen()
                      : ModuleScreen(feature: feature);
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => page));
                },
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: feature.color,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: AppColors.surface,
                        child: Icon(feature.icon, color: AppColors.ink),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(feature.subtitle),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
