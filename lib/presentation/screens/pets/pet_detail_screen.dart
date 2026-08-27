import 'package:flutter/material.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/adaptive_image.dart';
import '../../../core/widgets/paw_button.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/pet.dart';
import '../../../domain/models/user_role.dart';
import '../appointments/appointments_screen.dart';
import '../health/health_records_screen.dart';
import 'pet_identity_screen.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({
    required this.pet,
    required this.user,
    required this.services,
    super.key,
  });

  final Pet pet;
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.peach,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(background: _hero()),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 34),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 5),
                    Text('${pet.species} · ${pet.breed}'),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _PetFact(
                            label: pet.gender,
                            caption: 'Gender',
                            color: AppColors.lavender,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PetFact(
                            label: '${pet.age} years',
                            caption: 'Age',
                            color: AppColors.yellow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PetFact(
                            label: pet.species,
                            caption: 'Species',
                            color: AppColors.mint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'About ${pet.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pet.description.isEmpty
                          ? 'No additional care notes have been added.'
                          : pet.description,
                    ),
                    const SizedBox(height: 24),
                    if (user.role == UserRole.petOwner) ...[
                      _CareCard(
                        title: 'Pet QR Identity',
                        detail:
                            'Create a secure, scannable tag for ${pet.name}.',
                        icon: Icons.qr_code_2_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PetIdentityScreen(
                              user: user,
                              services: services,
                              seed: PetIdentitySeed.ownedPet(
                                pet: pet,
                                owner: user,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    StreamBuilder<List<HealthRecord>>(
                      stream: services.care.watchHealthRecords(pet.id),
                      builder: (context, snapshot) {
                        final upcoming =
                            (snapshot.data ?? const <HealthRecord>[])
                                .where((record) => record.dueDate != null)
                                .toList()
                              ..sort(
                                (a, b) => a.dueDate!.compareTo(b.dueDate!),
                              );
                        final record = upcoming.isEmpty ? null : upcoming.first;
                        return _CareCard(
                          title: record == null
                              ? 'Health records'
                              : 'Next ${record.type.label.toLowerCase()}',
                          detail: record == null
                              ? 'Open the protected care timeline.'
                              : '${record.title} · ${_day(record.dueDate!)}',
                          icon: Icons.vaccines_outlined,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => HealthRecordsScreen(
                                user: user,
                                services: services,
                                initialPet: pet,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Visible only to the owner and explicitly assigned veterinarian.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: user.role == UserRole.petOwner
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: PawButton(
                  label: 'Book Veterinary Care',
                  icon: Icons.calendar_month_outlined,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AppointmentsScreen(
                        user: user,
                        services: services,
                        initialPet: pet,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _hero() {
    if (pet.photoUrl != null && pet.photoUrl!.isNotEmpty) {
      return Container(
        color: AppColors.peach,
        child: AdaptiveImage(
          source: pet.photoUrl!,
          fit: BoxFit.cover,
          fallback: _fallbackHero(),
        ),
      );
    }
    return _fallbackHero();
  }

  Widget _fallbackHero() => Container(
    color: AppColors.peach,
    padding: const EdgeInsets.fromLTRB(35, 60, 20, 0),
    child: Image.asset(
      'assets/images/pawfect_pet_family_cutout.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
    ),
  );

  String _day(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _CareCard extends StatelessWidget {
  const _CareCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Ink(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.peachLight,
            child: Icon(icon, color: AppColors.orangeDeep),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(detail),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    ),
  );
}

class _PetFact extends StatelessWidget {
  const _PetFact({
    required this.label,
    required this.caption,
    required this.color,
  });
  final String label;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    ),
  );
}
