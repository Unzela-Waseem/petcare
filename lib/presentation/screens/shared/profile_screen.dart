import 'package:flutter/material.dart';

import '../../../core/config/app_services.dart';
import '../../../core/config/auth_validators.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/media_picker.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/repositories/care_repository.dart';
import '../../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.user,
    required this.controller,
    required this.services,
    super.key,
  });

  final AppUser user;
  final AuthController controller;
  final AppServices services;

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
          if (services.media.isDeviceOnly) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.phone_android_rounded),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Free device storage is active. New photos and medical files stay on this phone and are not synced to other devices.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.peach,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                _Avatar(user: user),
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
                      Chip(label: Text(user.role.label)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => _ProfileForm(
                      user: user,
                      controller: controller,
                      services: services,
                    ),
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
            subtitle: user.phone.isEmpty ? 'Add a phone number' : user.phone,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _ProfileForm(
                user: user,
                controller: controller,
                services: services,
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: 'Password & security',
            subtitle: 'Verified email · recent login required',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _PasswordForm(controller: controller),
            ),
          ),
          _SettingsTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Role & permissions',
            subtitle: '${user.role.label} · cannot be changed from the client',
            onTap: () => _show(
              context,
              'Role changes are blocked by Firestore security rules.',
            ),
          ),
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notification preferences',
            subtitle: AppEnvironment.usesFirebasePush
                ? 'Appointments, vaccines, adoption, and care tips'
                : 'On-device appointment and vaccine reminders',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) =>
                  _NotificationPreferences(user: user, services: services),
            ),
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

  void _show(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({
    required this.user,
    required this.controller,
    required this.services,
  });
  final AppUser user;
  final AuthController controller;
  final AppServices services;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  PickedMedia? _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Edit personal information',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_image?.name ?? 'Choose profile photo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          const SizedBox(height: 18),
          PawButton(label: 'Save Profile', busy: _busy, onPressed: _save),
        ],
      ),
    ),
  );

  Future<void> _pick() async {
    try {
      final image = await MediaPicker.image();
      if (image != null && mounted) setState(() => _image = image);
    } on FormatException catch (error) {
      if (mounted) _show(error.message);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2 || _phone.text.trim().length < 7) {
      _show('Enter a valid name and phone number.');
      return;
    }
    setState(() => _busy = true);
    try {
      String? path;
      var url = widget.user.photoUrl;
      if (_image != null) {
        final media = await widget.services.media.upload(
          path:
              'users/${widget.user.uid}/avatar/${DateTime.now().millisecondsSinceEpoch}_${_image!.name}',
          bytes: _image!.bytes,
          contentType: _image!.contentType,
        );
        path = media.path;
        url = media.downloadUrl;
      }
      await widget.services.care.updateProfile(
        user: widget.user,
        name: _name.text,
        phone: _phone.text,
        photoPath: path,
        photoUrl: url,
      );
      widget.controller.updateLocalProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        photoUrl: url,
      );
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure
              ? error.message
              : 'Profile could not be updated.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm({required this.controller});
  final AuthController controller;

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change password',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
            if (widget.controller.message != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.controller.message!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 18),
            PawButton(
              label: 'Change Password',
              busy: widget.controller.busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    final validation = AuthValidators.password(_next.text);
    if (validation != null) {
      _show(validation);
      return;
    }
    if (_next.text != _confirm.text) {
      _show('New passwords do not match.');
      return;
    }
    final success = await widget.controller.changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (success && mounted) Navigator.pop(context);
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _NotificationPreferences extends StatefulWidget {
  const _NotificationPreferences({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  State<_NotificationPreferences> createState() =>
      _NotificationPreferencesState();
}

class _NotificationPreferencesState extends State<_NotificationPreferences> {
  Map<String, bool>? _values;
  bool _busy = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: StreamBuilder<Map<String, bool>>(
      stream: widget.services.care.watchNotificationPreferences(
        widget.user.uid,
      ),
      builder: (context, snapshot) {
        final values = _values ?? snapshot.data;
        if (values == null) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: CircularProgressIndicator(),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notification preferences',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              ...const {
                'appointments': 'Appointment reminders',
                'vaccinations': 'Vaccination reminders',
                'adoption': 'Adoption updates',
                'blogs': 'New care tips',
              }.entries.map(
                (entry) => SwitchListTile(
                  value: values[entry.key] ?? true,
                  title: Text(entry.value),
                  onChanged: (value) =>
                      setState(() => _values = {...values, entry.key: value}),
                ),
              ),
              const SizedBox(height: 10),
              PawButton(
                label: 'Save Preferences',
                busy: _busy,
                onPressed: () => _save(values),
              ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _save(Map<String, bool> values) async {
    setState(() => _busy = true);
    try {
      await widget.services.care.updateNotificationPreferences(
        uid: widget.user.uid,
        preferences: values,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      return ClipOval(
        child: AdaptiveImage(
          source: user.photoUrl!,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          fallback: _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() => CircleAvatar(
    radius: 38,
    backgroundColor: AppColors.ink,
    child: Text(
      user.name
          .split(' ')
          .where((part) => part.isNotEmpty)
          .map((part) => part.characters.first)
          .take(2)
          .join(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
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
  Widget build(BuildContext context) => Padding(
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
