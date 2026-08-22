import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.user,
    required this.controller,
    super.key,
  });

  final AppUser user;
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: [
          Text(
            'Your profile',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.peach,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.ink,
                  child: Text(
                    user.name
                        .split(' ')
                        .map((part) => part.characters.first)
                        .take(2)
                        .join(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(user.email),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: () => _notice(
                    context,
                    'Profile editing requires Firebase configuration.',
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal information',
            subtitle: user.phone,
            onTap: () =>
                _notice(context, 'Name, phone, and photo are editable.'),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Password & security',
            subtitle: 'Verified email · secure session',
            onTap: () => _notice(
              context,
              'Password changes are handled by Firebase Authentication.',
            ),
          ),
          _SettingsTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Role & permissions',
            subtitle: '${user.role.label} · locked',
            onTap: () =>
                _notice(context, 'Roles cannot be changed from the client.'),
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notification preferences',
            subtitle: 'Appointments, vaccines, adoption updates',
            onTap: () =>
                _notice(context, 'Notification preferences will sync to FCM.'),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Privacy & support',
            subtitle: 'Contact, feedback, and data controls',
            onTap: () =>
                _notice(context, 'Support tools are available from Explore.'),
          ),
          const SizedBox(height: 18),
          PawButton(
            label: 'Sign Out Securely',
            icon: Icons.logout_rounded,
            backgroundColor: AppColors.yellow,
            busy: controller.busy,
            onPressed: controller.signOut,
          ),
        ],
      ),
    );
  }

  void _notice(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        tileColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.cream,
          child: Icon(icon, color: AppColors.ink),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
