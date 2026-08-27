import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/pet.dart';
import '../../../domain/models/public_pet_profile.dart';
import '../../../domain/repositories/care_repository.dart';

class PetIdentitySeed {
  const PetIdentitySeed({
    required this.sourceId,
    required this.sourceType,
    required this.petName,
    required this.species,
    required this.age,
    required this.gender,
    required this.contactName,
    required this.contactPhone,
    this.breed = '',
    this.photoUrl,
    this.description = '',
    this.emergencyNotes = '',
  });

  factory PetIdentitySeed.ownedPet({
    required Pet pet,
    required AppUser owner,
  }) => PetIdentitySeed(
    sourceId: pet.id,
    sourceType: PublicPetSourceType.ownedPet,
    petName: pet.name,
    species: pet.species,
    breed: pet.breed,
    age: pet.age,
    gender: pet.gender,
    photoUrl: pet.photoUrl,
    description: pet.description,
    contactName: owner.name,
    contactPhone: owner.phone,
  );

  factory PetIdentitySeed.shelterListing({
    required AdoptionListing listing,
    required ShelterProfile shelter,
  }) => PetIdentitySeed(
    sourceId: listing.id,
    sourceType: PublicPetSourceType.shelterListing,
    petName: listing.petName,
    species: listing.species,
    age: listing.age,
    gender: listing.gender,
    photoUrl: listing.photoUrl,
    description: listing.description,
    emergencyNotes: listing.healthStatus,
    contactName: shelter.name,
    contactPhone: shelter.phone,
  );

  final String sourceId;
  final PublicPetSourceType sourceType;
  final String petName;
  final String species;
  final String breed;
  final int age;
  final String gender;
  final String? photoUrl;
  final String description;
  final String emergencyNotes;
  final String contactName;
  final String contactPhone;
}

class PetIdentityScreen extends StatefulWidget {
  const PetIdentityScreen({
    required this.user,
    required this.services,
    required this.seed,
    super.key,
  });

  final AppUser user;
  final AppServices services;
  final PetIdentitySeed seed;

  @override
  State<PetIdentityScreen> createState() => _PetIdentityScreenState();
}

class _PetIdentityScreenState extends State<PetIdentityScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _busy = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('Pet QR Identity')),
    body: StreamBuilder<PublicPetProfile?>(
      stream: widget.services.care.watchManagedPublicPetProfile(
        managerId: widget.user.uid,
        sourceType: widget.seed.sourceType,
        sourceId: widget.seed.sourceId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _CenteredMessage(
            icon: Icons.lock_outline_rounded,
            title: 'QR identity unavailable',
            detail: _errorText(snapshot.error),
          );
        }
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data;
        return profile == null ? _emptyState() : _profileState(profile);
      },
    ),
  );

  Widget _emptyState() => ListView(
    padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
    children: [
      Center(
        child: Container(
          width: 116,
          height: 116,
          decoration: const BoxDecoration(
            color: AppColors.peachLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.qr_code_2_rounded,
            size: 62,
            color: AppColors.orangeDeep,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Create ${widget.seed.petName}’s QR identity',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 10),
      const Text(
        'Anyone can scan the tag with a normal phone camera to see the safe public profile and contact you. Private medical records are never included.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      const _PrivacyCard(),
      const SizedBox(height: 24),
      PawButton(
        label: 'Create Secure QR',
        icon: Icons.qr_code_2_rounded,
        busy: _busy,
        onPressed: () => _openForm(null),
      ),
    ],
  );

  Widget _profileState(PublicPetProfile profile) {
    final link = publicPetProfileUrl(profile.id);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.peachLight, AppColors.yellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.isLost
                          ? 'Lost pet alert active'
                          : 'QR tag active',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      profile.isLost
                          ? Icons.location_searching_rounded
                          : Icons.verified_rounded,
                      size: 17,
                    ),
                    label: Text(profile.isLost ? 'LOST' : 'ACTIVE'),
                    backgroundColor: profile.isLost
                        ? AppColors.lavender
                        : AppColors.mint,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: link,
                        size: 236,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.ink,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.petName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        'Scan to view my PawfectCare identity',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _shareQr(profile),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download / Share QR'),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyLink(link),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Copy Link'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PublicPetProfileScreen(
                    publicId: profile.id,
                    care: widget.services.care,
                  ),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ManagedProfileSummary(profile: profile),
        const SizedBox(height: 12),
        const _PrivacyCard(),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _openForm(profile),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Public Info'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _regenerate(profile),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : () => _disable(profile),
          icon: const Icon(Icons.link_off_rounded, color: AppColors.danger),
          label: const Text(
            'Disable this QR',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(PublicPetProfile? profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PetIdentityFormScreen(
          user: widget.user,
          services: widget.services,
          seed: widget.seed,
          profile: profile,
        ),
      ),
    );
  }

  Future<void> _shareQr(PublicPetProfile profile) async {
    setState(() => _busy = true);
    final shareBox = context.findRenderObject() as RenderBox?;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary = _qrKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw const FormatException('QR image is not ready yet.');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw const FormatException('QR image could not be prepared.');
      }
      final bytes = byteData.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          title: '${profile.petName} PawfectCare QR',
          subject: '${profile.petName} pet identity',
          text:
              'Scan ${profile.petName}’s PawfectCare identity or open ${publicPetProfileUrl(profile.id)}',
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: [
            'pawfectcare-${_fileName(profile.petName)}-qr.png',
          ],
          downloadFallbackEnabled: true,
          sharePositionOrigin: shareBox == null
              ? null
              : shareBox.localToGlobal(Offset.zero) & shareBox.size,
        ),
      );
    } on Object catch (error) {
      if (mounted) _show(_errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) _show('Public QR link copied.');
  }

  Future<void> _regenerate(PublicPetProfile profile) async {
    final confirmed = await _confirm(
      title: 'Regenerate QR?',
      message:
          'The printed old QR will stop working. A new permanent link will be created.',
      action: 'Regenerate',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await widget.services.care.deletePublicPetProfile(profile.id);
      await widget.services.care.savePublicPetProfile(profile.copyWith(id: ''));
      if (mounted) _show('A new secure QR identity was created.');
    } on Object catch (error) {
      if (mounted) _show(_errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable(PublicPetProfile profile) async {
    final confirmed = await _confirm(
      title: 'Disable this QR?',
      message:
          'Anyone scanning the current tag will see that the profile is unavailable. You can create a new QR later.',
      action: 'Disable',
    );
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await widget.services.care.deletePublicPetProfile(profile.id);
      if (mounted) _show('QR identity disabled.');
    } on Object catch (error) {
      if (mounted) _show(_errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class PetIdentityFormScreen extends StatefulWidget {
  const PetIdentityFormScreen({
    required this.user,
    required this.services,
    required this.seed,
    this.profile,
    super.key,
  });

  final AppUser user;
  final AppServices services;
  final PetIdentitySeed seed;
  final PublicPetProfile? profile;

  @override
  State<PetIdentityFormScreen> createState() => _PetIdentityFormScreenState();
}

class _PetIdentityFormScreenState extends State<PetIdentityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contactName;
  late final TextEditingController _contactPhone;
  late final TextEditingController _allergies;
  late final TextEditingController _emergencyNotes;
  late bool _showContact;
  late bool _isLost;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _contactName = TextEditingController(
      text: profile?.contactName ?? widget.seed.contactName,
    );
    _contactPhone = TextEditingController(
      text: profile?.contactPhone.isNotEmpty == true
          ? profile!.contactPhone
          : widget.seed.contactPhone,
    );
    _allergies = TextEditingController(text: profile?.allergies);
    _emergencyNotes = TextEditingController(
      text: profile?.emergencyNotes.isNotEmpty == true
          ? profile!.emergencyNotes
          : widget.seed.emergencyNotes,
    );
    _showContact = profile == null || profile.contactPhone.isNotEmpty;
    _isLost = profile?.isLost ?? false;
  }

  @override
  void dispose() {
    _contactName.dispose();
    _contactPhone.dispose();
    _allergies.dispose();
    _emergencyNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: Text(
        widget.profile == null ? 'Create Pet QR' : 'Edit Public Info',
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          _PetMiniHeader(seed: widget.seed),
          const SizedBox(height: 18),
          SwitchListTile.adaptive(
            value: _isLost,
            onChanged: (value) => setState(() => _isLost = value),
            title: const Text('Mark as lost'),
            subtitle: const Text(
              'Shows a prominent LOST alert to anyone who scans the QR.',
            ),
            activeTrackColor: AppColors.orange,
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _allergies,
            maxLength: 250,
            decoration: const InputDecoration(
              labelText: 'Important allergies (optional)',
              hintText: 'Example: Allergic to chicken',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emergencyNotes,
            maxLines: 3,
            maxLength: 350,
            decoration: const InputDecoration(
              labelText: 'Emergency note (optional)',
              hintText: 'Safe handling or urgent care information',
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            value: _showContact,
            onChanged: (value) => setState(() => _showContact = value),
            title: const Text('Show contact actions'),
            subtitle: const Text(
              'Allows the finder to call or send an “I found this pet” message.',
            ),
            activeTrackColor: AppColors.orange,
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          if (_showContact) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactName,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Contact name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactPhone,
              keyboardType: TextInputType.phone,
              maxLength: 30,
              decoration: const InputDecoration(labelText: 'Contact number'),
              validator: _required,
            ),
          ],
          const SizedBox(height: 8),
          const _PrivacyCard(),
          const SizedBox(height: 22),
          PawButton(
            label: widget.profile == null
                ? 'Generate Secure QR'
                : 'Save Public Information',
            icon: Icons.qr_code_2_rounded,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final seed = widget.seed;
      final profile = PublicPetProfile(
        id: widget.profile?.id ?? '',
        sourceId: seed.sourceId,
        sourceType: seed.sourceType,
        managerId: widget.user.uid,
        petName: seed.petName,
        species: seed.species,
        breed: seed.breed,
        age: seed.age,
        gender: seed.gender,
        photoUrl: seed.photoUrl,
        description: seed.description,
        allergies: _allergies.text.trim(),
        emergencyNotes: _emergencyNotes.text.trim(),
        contactName: _showContact ? _contactName.text.trim() : '',
        contactPhone: _showContact ? _contactPhone.text.trim() : '',
        isLost: _isLost,
      );
      await widget.services.care.savePublicPetProfile(profile);
      if (mounted) Navigator.pop(context);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'This field is required when contact actions are enabled.'
      : null;
}

class PublicPetProfileScreen extends StatelessWidget {
  const PublicPetProfileScreen({
    required this.publicId,
    required this.care,
    super.key,
  });

  final String publicId;
  final CareRepository care;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    body: SafeArea(
      child: StreamBuilder<PublicPetProfile?>(
        stream: care.watchPublicPetProfile(publicId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _UnavailablePublicProfile();
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          if (profile == null || !profile.active) {
            return const _UnavailablePublicProfile();
          }
          return _PublicProfileBody(profile: profile);
        },
      ),
    ),
  );
}

class _PublicProfileBody extends StatelessWidget {
  const _PublicProfileBody({required this.profile});

  final PublicPetProfile profile;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.orange,
                child: Icon(Icons.pets_rounded, color: AppColors.ink),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'PawfectCare Pet Identity',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
              Chip(
                label: Text(profile.isLost ? 'LOST PET' : 'VERIFIED PROFILE'),
                backgroundColor: profile.isLost
                    ? AppColors.lavender
                    : AppColors.mint,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SizedBox(
              height: 330,
              child: profile.photoUrl?.isNotEmpty == true
                  ? AdaptiveImage(
                      source: profile.photoUrl!,
                      width: double.infinity,
                      height: 330,
                      fit: BoxFit.cover,
                      fallback: const _PublicPetFallback(),
                    )
                  : const _PublicPetFallback(),
            ),
          ),
          const SizedBox(height: 18),
          if (profile.isLost) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_searching_rounded),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I am lost. Please use the contact buttons below to help me get home.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            profile.petName,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 5),
          Text(
            [
              profile.species,
              profile.breed,
              '${profile.age} years',
              profile.gender,
            ].where((value) => value.trim().isNotEmpty).join(' · '),
          ),
          if (profile.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(profile.description),
          ],
          if (profile.allergies.isNotEmpty ||
              profile.emergencyNotes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.peachLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined),
                      SizedBox(width: 8),
                      Text(
                        'Emergency information',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  if (profile.allergies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Allergies: ${profile.allergies}'),
                  ],
                  if (profile.emergencyNotes.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(profile.emergencyNotes),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (profile.contactPhone.isNotEmpty) ...[
            Text(
              'Contact ${profile.contactName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            PawButton(
              label: 'Call ${profile.contactName}',
              icon: Icons.call_outlined,
              onPressed: () => _launchContact(
                context,
                Uri(scheme: 'tel', path: _dialable(profile.contactPhone)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _launchContact(
                context,
                Uri(
                  scheme: 'sms',
                  path: _dialable(profile.contactPhone),
                  queryParameters: {
                    'body':
                        'Hi ${profile.contactName}, I found ${profile.petName}. I scanned the PawfectCare QR tag.',
                  },
                ),
              ),
              icon: const Icon(Icons.sms_outlined),
              label: const Text('I Found This Pet'),
            ),
          ] else
            const _PrivacyCard(
              text:
                  'The manager has hidden direct contact information for this pet.',
            ),
          const SizedBox(height: 20),
          const Text(
            'This public identity intentionally excludes private medical records, appointments, account details, and home address.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    ),
  );

  Future<void> _launchContact(BuildContext context, Uri uri) async {
    if (await launchUrl(uri)) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This device cannot open that contact action.'),
      ),
    );
  }
}

class _ManagedProfileSummary extends StatelessWidget {
  const _ManagedProfileSummary({required this.profile});

  final PublicPetProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Public information',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        _SummaryLine(label: 'Pet', value: profile.petName),
        _SummaryLine(
          label: 'Contact',
          value: profile.contactPhone.isEmpty
              ? 'Hidden'
              : '${profile.contactName} · ${profile.contactPhone}',
        ),
        _SummaryLine(
          label: 'Allergies',
          value: profile.allergies.isEmpty ? 'Not shared' : profile.allergies,
        ),
        _SummaryLine(
          label: 'Emergency note',
          value: profile.emergencyNotes.isEmpty
              ? 'Not shared'
              : profile.emergencyNotes,
        ),
      ],
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _PetMiniHeader extends StatelessWidget {
  const _PetMiniHeader({required this.seed});

  final PetIdentitySeed seed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.peachLight,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 70,
            height: 70,
            child: seed.photoUrl?.isNotEmpty == true
                ? AdaptiveImage(
                    source: seed.photoUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    fallback: const _PublicPetFallback(),
                  )
                : const _PublicPetFallback(),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(seed.petName, style: Theme.of(context).textTheme.titleLarge),
              Text(
                [
                  seed.species,
                  seed.breed,
                  '${seed.age} years',
                ].where((value) => value.trim().isNotEmpty).join(' · '),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    this.text =
        'Only the information shown here becomes public. Medical reports, appointments, login details, and home address stay private.',
  });

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: AppColors.mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _UnavailablePublicProfile extends StatelessWidget {
  const _UnavailablePublicProfile();

  @override
  Widget build(BuildContext context) => const _CenteredMessage(
    icon: Icons.link_off_rounded,
    title: 'Pet profile unavailable',
    detail:
        'This QR was disabled, regenerated, or the pet profile is no longer public.',
  );
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: AppColors.orangeDeep),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _PublicPetFallback extends StatelessWidget {
  const _PublicPetFallback();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.peach,
    padding: const EdgeInsets.all(12),
    child: Image.asset(
      'assets/images/pawfect_pet_family_cutout.png',
      fit: BoxFit.contain,
    ),
  );
}

String publicPetProfileUrl(String publicId) {
  final base = Uri.parse(AppEnvironment.publicWebBaseUrl);
  return base.replace(queryParameters: {'pet': publicId}).toString();
}

String _dialable(String phone) => phone.replaceAll(RegExp(r'[^+0-9]'), '');

String _fileName(String value) {
  final safe = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return safe.replaceAll(RegExp(r'^-+|-+$'), '');
}

String _errorText(Object? error) => switch (error) {
  CareFailure failure => failure.message,
  FormatException failure => failure.message,
  _ => 'The QR identity could not be updated securely.',
};
