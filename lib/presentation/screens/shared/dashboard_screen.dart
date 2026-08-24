import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_services.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/user_role.dart';
import 'feature_catalog.dart';
import 'feature_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.user,
    required this.services,
    super.key,
  });

  final AppUser user;
  final AppServices services;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final features = FeatureCatalog.forRole(widget.user.role)
        .where(
          (feature) =>
              feature.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            sliver: SliverList.list(
              children: [
                _Header(
                  user: widget.user,
                  onNotifications: () => _openFeature(
                    context,
                    FeatureCatalog.forRole(
                      widget.user.role,
                    ).firstWhere((item) => item.title == 'Notifications'),
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search pets, care, or services',
                    prefixIcon: Icon(Icons.search_rounded),
                    suffixIcon: Icon(Icons.tune_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                _RoleChips(role: widget.user.role),
                const SizedBox(height: 22),
                _buildHero(context),
                const SizedBox(height: 24),
                SectionHeading(
                  title: _sectionTitle(widget.user.role),
                  action: '${features.length} tools',
                ),
                const SizedBox(height: 8),
                if (features.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No matching care tools.')),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720 ? 4 : 2;
                      final width =
                          (constraints.maxWidth - ((columns - 1) * 12)) /
                          columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: features
                            .map(
                              (feature) => SizedBox(
                                width: width,
                                child: _FeatureTile(
                                  feature: feature,
                                  onTap: () => _openFeature(context, feature),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                const SizedBox(height: 26),
                _PrivacyCard(role: widget.user.role),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(UserRole role) => switch (role) {
    UserRole.petOwner => 'Care made simple',
    UserRole.veterinarian => 'Clinical workspace',
    UserRole.shelterAdmin => 'Shelter workspace',
  };

  Widget _buildHero(BuildContext context) {
    final role = widget.user.role;
    final feature = role == UserRole.shelterAdmin
        ? FeatureCatalog.forRole(
            role,
          ).firstWhere((item) => item.title == 'Adoption Requests')
        : FeatureCatalog.forRole(role).first;
    void openHeroFeature() => _openFeature(context, feature);
    if (role != UserRole.shelterAdmin) {
      return _HeroCard(role: role, onTap: openHeroFeature);
    }
    return StreamBuilder<List<AdoptionRequest>>(
      stream: widget.services.care.watchAdoptionRequests(widget.user),
      builder: (context, snapshot) => _HeroCard(
        role: role,
        adoptionRequests: snapshot.data ?? const [],
        requestLoadFailed: snapshot.hasError,
        onTap: openHeroFeature,
      ),
    );
  }

  void _openFeature(BuildContext context, FeatureAction feature) {
    FeatureRouter.open(
      context,
      feature: feature,
      user: widget.user,
      services: widget.services,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.onNotifications});
  final AppUser user;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final nameParts = user.name.split(' ');
    final firstName = user.role == UserRole.veterinarian && nameParts.length > 1
        ? '${nameParts[0]} ${nameParts[1]}'
        : nameParts.first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $firstName',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 3),
              Text(_greeting()),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.peachLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            user.role.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 9),
        Badge(
          smallSize: 9,
          backgroundColor: AppColors.orangeDeep,
          child: IconButton.filledTonal(
            tooltip: 'Notifications',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink,
            ),
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀';
    if (hour < 18) return 'Good afternoon ☀';
    return 'Good evening ☾';
  }
}

class _RoleChips extends StatelessWidget {
  const _RoleChips({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final labels = switch (role) {
      UserRole.petOwner => const [
        (Icons.pets_rounded, 'Pets'),
        (Icons.health_and_safety_outlined, 'Health'),
        (Icons.medical_services_outlined, 'Vets'),
        (Icons.favorite_outline_rounded, 'Adopt'),
      ],
      UserRole.veterinarian => const [
        (Icons.today_outlined, 'Today'),
        (Icons.pets_outlined, 'Patients'),
        (Icons.history_rounded, 'History'),
        (Icons.schedule_outlined, 'Slots'),
      ],
      UserRole.shelterAdmin => const [
        (Icons.pets_outlined, 'Listings'),
        (Icons.favorite_outline_rounded, 'Requests'),
        (Icons.groups_outlined, 'People'),
        (Icons.auto_awesome_outlined, 'Stories'),
      ],
    };
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return Container(
            width: 82,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.orange : AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: selected ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(labels[index].$1, size: 22),
                const SizedBox(height: 4),
                Text(
                  labels[index].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.role,
    required this.onTap,
    this.adoptionRequests = const [],
    this.requestLoadFailed = false,
  });
  final UserRole role;
  final VoidCallback onTap;
  final List<AdoptionRequest> adoptionRequests;
  final bool requestLoadFailed;

  @override
  Widget build(BuildContext context) {
    final pendingRequests = adoptionRequests
        .where((request) => request.status == RequestStatus.pending)
        .toList();
    final latestPending = pendingRequests.isEmpty
        ? null
        : pendingRequests.first;
    final content = switch (role) {
      UserRole.petOwner => (
        eyebrow: 'NEXT UP',
        title: 'Luna is doing\npawfectly.',
        detail: 'Booster due in 7 days',
        button: 'View Luna',
      ),
      UserRole.veterinarian => (
        eyebrow: '09:30 · CONFIRMED',
        title: 'Luna’s wellness\nvisit is next.',
        detail: 'Owner: Jamie Parker',
        button: 'Open Patient',
      ),
      UserRole.shelterAdmin => (
        eyebrow: requestLoadFailed
            ? 'REQUESTS UNAVAILABLE'
            : '${pendingRequests.length} PENDING ${pendingRequests.length == 1 ? 'REQUEST' : 'REQUESTS'}',
        title: requestLoadFailed
            ? 'Applications could\nnot be loaded.'
            : latestPending != null
            ? '${latestPending.petName} may have\nfound a home.'
            : adoptionRequests.isEmpty
            ? 'No applications\nwaiting.'
            : 'All applications\nreviewed.',
        detail: requestLoadFailed
            ? 'Tap to open the request inbox'
            : latestPending != null
            ? '${latestPending.ownerName} is ready for review'
            : '${adoptionRequests.length} total application${adoptionRequests.length == 1 ? '' : 's'}',
        button: pendingRequests.isEmpty ? 'View Requests' : 'Review Now',
      ),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.peach,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -24,
              bottom: -12,
              width: 230,
              height: 230,
              child: Image.asset(
                'assets/images/pawfect_pet_family_cutout.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
            Positioned(
              right: 24,
              top: 22,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.orangeDeep.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.eyebrow,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 260,
                      child: Text(
                        content.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(content.detail),
                    const Spacer(),
                    SizedBox(
                      width: 165,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.pets_rounded, size: 18),
                        label: Text(content.button),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature, required this.onTap});
  final FeatureAction feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: 148,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: feature.color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(feature.icon, size: 22),
            ),
            const Spacer(),
            Text(
              feature.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              feature.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.orange,
            child: Icon(Icons.lock_outline_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Private by design',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(switch (role) {
                  UserRole.petOwner =>
                    'Only you and assigned care teams can access your pet’s private records.',
                  UserRole.veterinarian =>
                    'Patient access is limited to active assignments and appointments.',
                  UserRole.shelterAdmin =>
                    'You can manage only listings and requests for your own shelter.',
                }, style: const TextStyle(color: Color(0xFFCBC7C0), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
