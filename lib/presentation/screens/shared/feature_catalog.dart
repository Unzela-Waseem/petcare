import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/user_role.dart';

class FeatureAction {
  const FeatureAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.canCreate = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool canCreate;
}

abstract final class FeatureCatalog {
  static List<FeatureAction> forRole(UserRole role) => switch (role) {
    UserRole.petOwner => owner,
    UserRole.veterinarian => veterinarian,
    UserRole.shelterAdmin => shelter,
  };

  static const owner = [
    FeatureAction(
      title: 'My Pets',
      subtitle: 'Profiles & daily care',
      icon: Icons.pets_outlined,
      color: AppColors.peachLight,
      canCreate: true,
    ),
    FeatureAction(
      title: 'Health Records',
      subtitle: 'Vaccines & history',
      icon: Icons.health_and_safety_outlined,
      color: AppColors.mint,
    ),
    FeatureAction(
      title: 'Appointments',
      subtitle: 'Book a trusted vet',
      icon: Icons.calendar_month_outlined,
      color: AppColors.lavender,
      canCreate: true,
    ),
    FeatureAction(
      title: 'Pet Store',
      subtitle: 'Food, toys & care',
      icon: Icons.shopping_bag_outlined,
      color: AppColors.yellow,
    ),
    FeatureAction(
      title: 'Care Tips',
      subtitle: 'Helpful expert guides',
      icon: Icons.auto_stories_outlined,
      color: AppColors.peachLight,
    ),
    FeatureAction(
      title: 'Adoption',
      subtitle: 'Meet a new friend',
      icon: Icons.favorite_border_rounded,
      color: AppColors.mint,
      canCreate: true,
    ),
    FeatureAction(
      title: 'Notifications',
      subtitle: 'Reminders & updates',
      icon: Icons.notifications_none_rounded,
      color: AppColors.lavender,
    ),
    FeatureAction(
      title: 'Contact & Feedback',
      subtitle: 'Locations & support',
      icon: Icons.forum_outlined,
      color: AppColors.yellow,
      canCreate: true,
    ),
  ];

  static const veterinarian = [
    FeatureAction(
      title: "Today's Appointments",
      subtitle: 'Your clinical schedule',
      icon: Icons.event_available_outlined,
      color: AppColors.peachLight,
    ),
    FeatureAction(
      title: 'Assigned Pets',
      subtitle: 'Authorized patients only',
      icon: Icons.pets_outlined,
      color: AppColors.mint,
    ),
    FeatureAction(
      title: 'Patient History',
      subtitle: 'Clinical timelines',
      icon: Icons.history_rounded,
      color: AppColors.lavender,
    ),
    FeatureAction(
      title: 'Calendar',
      subtitle: 'Availability & visits',
      icon: Icons.calendar_month_outlined,
      color: AppColors.yellow,
      canCreate: true,
    ),
    FeatureAction(
      title: 'Medical Records',
      subtitle: 'Diagnosis & treatment',
      icon: Icons.medical_information_outlined,
      color: AppColors.peachLight,
      canCreate: true,
    ),
    FeatureAction(
      title: 'Notifications',
      subtitle: 'Patient reminders',
      icon: Icons.notifications_none_rounded,
      color: AppColors.mint,
    ),
  ];

  static const shelter = [
    FeatureAction(
      title: 'Pet Listings',
      subtitle: 'Available companions',
      icon: Icons.pets_outlined,
      color: AppColors.peachLight,
      canCreate: true,
    ),
    FeatureAction(
      title: 'Adoption Requests',
      subtitle: 'Review applications',
      icon: Icons.volunteer_activism_outlined,
      color: AppColors.mint,
    ),
    FeatureAction(
      title: 'Success Stories',
      subtitle: 'Share happy endings',
      icon: Icons.auto_awesome_outlined,
      color: AppColors.lavender,
      canCreate: true,
    ),
    FeatureAction(
      title: 'Volunteer Requests',
      subtitle: 'Community support',
      icon: Icons.groups_outlined,
      color: AppColors.yellow,
    ),
    FeatureAction(
      title: 'Contact Messages',
      subtitle: 'Shelter inquiries',
      icon: Icons.mark_email_unread_outlined,
      color: AppColors.peachLight,
    ),
    FeatureAction(
      title: 'Notifications',
      subtitle: 'Adoption updates',
      icon: Icons.notifications_none_rounded,
      color: AppColors.mint,
    ),
  ];
}
