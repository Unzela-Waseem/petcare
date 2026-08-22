import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_services.dart';
import '../../../domain/models/app_user.dart';
import 'feature_catalog.dart';
import 'feature_router.dart';

class ModuleHubScreen extends StatelessWidget {
  const ModuleHubScreen({
    required this.user,
    required this.services,
    super.key,
  });
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final features = FeatureCatalog.forRole(user.role);
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
            'Tools selected for your ${user.role.label.toLowerCase()} permissions.',
          ),
          const SizedBox(height: 22),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  FeatureRouter.open(
                    context,
                    feature: feature,
                    user: user,
                    services: services,
                  );
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
