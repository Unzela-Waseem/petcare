import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/repositories/care_repository.dart';
import '../adoption/shelter_operations_screen.dart';

class ContactFeedbackScreen extends StatelessWidget {
  const ContactFeedbackScreen({
    required this.user,
    required this.services,
    super.key,
  });
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('Contact & Feedback')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text(
          'How can we help?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        _ActionCard(
          color: AppColors.peachLight,
          icon: Icons.mark_email_unread_outlined,
          title: 'Shelter inquiry',
          subtitle: 'Ask a shelter a private question.',
          onTap: () => _communityForm(context, 'inquiry'),
        ),
        _ActionCard(
          color: AppColors.mint,
          icon: Icons.groups_outlined,
          title: 'Volunteer or donate',
          subtitle: 'Offer time, fostering, supplies, or donation interest.',
          onTap: () => _communityForm(context, 'volunteer'),
        ),
        _ActionCard(
          color: AppColors.lavender,
          icon: Icons.feedback_outlined,
          title: 'App feedback',
          subtitle: 'Send a suggestion, bug report, or feedback.',
          onTap: () => _feedbackForm(context),
        ),
        const SizedBox(height: 10),
        Text('Nearby care', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        StreamBuilder<List<VeterinarianProfile>>(
          stream: services.care.watchVeterinarians(),
          builder: (context, snapshot) => Column(
            children: (snapshot.data ?? const <VeterinarianProfile>[])
                .where((item) => item.location.isNotEmpty)
                .map(
                  (vet) => _LocationTile(
                    icon: Icons.local_hospital_outlined,
                    name: vet.clinicName.isEmpty ? vet.name : vet.clinicName,
                    location: vet.location,
                    onTap: () =>
                        _maps(context, '${vet.clinicName} ${vet.location}'),
                  ),
                )
                .toList(),
          ),
        ),
        StreamBuilder<List<ShelterProfile>>(
          stream: services.care.watchShelters(),
          builder: (context, snapshot) => Column(
            children: (snapshot.data ?? const <ShelterProfile>[])
                .map(
                  (shelter) => _LocationTile(
                    icon: Icons.home_work_outlined,
                    name: shelter.name,
                    location: shelter.location,
                    onTap: () =>
                        _maps(context, '${shelter.name} ${shelter.location}'),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => CommunityRequestsScreen(
                user: user,
                services: services,
                module: CommunityModule.volunteer,
              ),
            ),
          ),
          icon: const Icon(Icons.volunteer_activism_outlined),
          label: const Text('My volunteer & donation requests'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => CommunityRequestsScreen(
                user: user,
                services: services,
                module: CommunityModule.contact,
              ),
            ),
          ),
          icon: const Icon(Icons.history_rounded),
          label: const Text('My submitted inquiries'),
        ),
      ],
    ),
  );

  Future<void> _communityForm(BuildContext context, String initialKind) async {
    final shelters = await services.care.watchShelters().first;
    if (!context.mounted) return;
    if (shelters.isEmpty) {
      _show(context, 'No shelter profiles are available yet.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CommunityForm(
        user: user,
        services: services,
        shelters: shelters,
        initialKind: initialKind,
      ),
    );
  }

  Future<void> _feedbackForm(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _FeedbackForm(user: user, services: services),
      );

  Future<void> _maps(BuildContext context, String query) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      _show(context, 'Google Maps could not be opened.');
    }
  }

  void _show(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _CommunityForm extends StatefulWidget {
  const _CommunityForm({
    required this.user,
    required this.services,
    required this.shelters,
    required this.initialKind,
  });
  final AppUser user;
  final AppServices services;
  final List<ShelterProfile> shelters;
  final String initialKind;

  @override
  State<_CommunityForm> createState() => _CommunityFormState();
}

class _CommunityFormState extends State<_CommunityForm> {
  late ShelterProfile _shelter;
  late String _kind;
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _shelter = widget.shelters.first;
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _message.dispose();
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
            'Contact a shelter',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _shelter.id,
            decoration: const InputDecoration(labelText: 'Shelter'),
            items: widget.shelters
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: (id) =>
                _shelter = widget.shelters.firstWhere((item) => item.id == id),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            decoration: const InputDecoration(labelText: 'Request type'),
            items: const [
              DropdownMenuItem(
                value: 'inquiry',
                child: Text('Shelter inquiry'),
              ),
              DropdownMenuItem(
                value: 'volunteer',
                child: Text('Volunteer request'),
              ),
              DropdownMenuItem(
                value: 'donation',
                child: Text('Donation interest'),
              ),
            ],
            onChanged: (value) => _kind = value ?? _kind,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLines: 4,
            maxLength: 1200,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 12),
          PawButton(label: 'Submit Privately', busy: _busy, onPressed: _submit),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.services.care.submitCommunityRequest(
        user: widget.user,
        shelterId: _shelter.id,
        kind: _kind,
        message: _message.text,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final label = switch (_kind) {
          'volunteer' => 'Volunteer request',
          'donation' => 'Donation interest',
          _ => 'Shelter inquiry',
        };
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(content: Text('$label submitted privately.')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        _show(
          error is CareFailure
              ? error.message
              : 'Message could not be submitted.',
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

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  String _type = 'feedback';
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
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
            'App feedback',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'suggestion', child: Text('Suggestion')),
              DropdownMenuItem(value: 'bug', child: Text('Bug report')),
              DropdownMenuItem(
                value: 'feedback',
                child: Text('General feedback'),
              ),
            ],
            onChanged: (value) => _type = value ?? _type,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLines: 5,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 12),
          PawButton(label: 'Send Feedback', busy: _busy, onPressed: _submit),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.services.care.submitFeedback(
        user: widget.user,
        type: _type,
        message: _message.text,
      );
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is CareFailure
                  ? error.message
                  : 'Feedback could not be sent.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(16),
      tileColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      leading: CircleAvatar(
        backgroundColor: AppColors.surface,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    ),
  );
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.icon,
    required this.name,
    required this.location,
    required this.onTap,
  });
  final IconData icon;
  final String name;
  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon),
    title: Text(name),
    subtitle: Text(location),
    trailing: const Icon(Icons.map_outlined),
  );
}
