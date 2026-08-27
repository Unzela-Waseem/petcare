import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_services.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/utils/search_matcher.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/user_role.dart';
import 'feature_catalog.dart';
import 'feature_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.user,
    required this.services,
    this.onMenu,
    super.key,
  });

  final AppUser user;
  final AppServices services;
  final VoidCallback? onMenu;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final features = FeatureCatalog.forRole(widget.user.role)
        .where(
          (feature) =>
              SearchMatcher.matches(query, [feature.title, feature.subtitle]),
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
                  services: widget.services,
                  onMenu: widget.onMenu,
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
                if (query.isEmpty) ...[
                  const SizedBox(height: 18),
                  _QuickAccessStrip(
                    role: widget.user.role,
                    onOpen: (feature) => _openFeature(context, feature),
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  _SearchDestinations(
                    query: query,
                    features: _searchFeatures(widget.user.role),
                    onOpen: (feature) => FeatureRouter.open(
                      context,
                      feature: feature,
                      user: widget.user,
                      services: widget.services,
                      initialQuery: query,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                if (query.isEmpty) ...[
                  _buildHero(context),
                  const SizedBox(height: 24),
                ],
                SectionHeading(
                  title: query.isEmpty
                      ? _sectionTitle(widget.user.role)
                      : 'Matching tools',
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

  List<FeatureAction> _searchFeatures(UserRole role) {
    final titles = switch (role) {
      UserRole.petOwner => const [
        'My Pets',
        'Health Records',
        'Care Tips',
        'Pet Store',
        'Adoption',
      ],
      UserRole.veterinarian => const [
        'Assigned Pets',
        'Medical Records',
        'Care Tips',
      ],
      UserRole.shelterAdmin => const ['Pet Listings', 'Care Tips'],
    };
    final catalog = FeatureCatalog.forRole(role);
    return titles
        .map((title) => catalog.firstWhere((item) => item.title == title))
        .toList();
  }

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

class _SearchDestinations extends StatelessWidget {
  const _SearchDestinations({
    required this.query,
    required this.features,
    required this.onOpen,
  });

  final String query;
  final List<FeatureAction> features;
  final ValueChanged<FeatureAction> onOpen;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search authorized data for “$query”',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text('Choose where you want to search.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features
              .map(
                (feature) => ActionChip(
                  avatar: Icon(feature.icon, size: 18),
                  label: Text('Search in ${feature.title}'),
                  onPressed: () => onOpen(feature),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.services,
    required this.onNotifications,
    this.onMenu,
  });
  final AppUser user;
  final AppServices services;
  final VoidCallback onNotifications;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final nameParts = user.name.split(' ');
    final firstName = user.role == UserRole.veterinarian && nameParts.length > 1
        ? '${nameParts[0]} ${nameParts[1]}'
        : nameParts.first;
    return Row(
      children: [
        if (onMenu != null) ...[
          IconButton.filled(
            tooltip: 'Open menu',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              minimumSize: const Size(46, 46),
            ),
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 12),
        ],
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
        StreamBuilder<List<UserNotification>>(
          stream: services.care.watchActivityNotifications(user),
          builder: (context, snapshot) {
            final unreadCount = snapshot.hasData
                ? snapshot.data!.where((n) => n.readAt == null).length
                : 0;
            return Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
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
            );
          },
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

class _QuickAccessStrip extends StatelessWidget {
  const _QuickAccessStrip({required this.role, required this.onOpen});

  final UserRole role;
  final ValueChanged<FeatureAction> onOpen;

  @override
  Widget build(BuildContext context) {
    final titles = switch (role) {
      UserRole.petOwner => const [
        'My Pets',
        'Health Records',
        'Appointments',
        'Adoption',
      ],
      UserRole.veterinarian => const [
        "Today's Appointments",
        'Assigned Pets',
        'Medical Records',
        'Calendar',
      ],
      UserRole.shelterAdmin => const [
        'Pet Listings',
        'Adoption Requests',
        'Volunteer Requests',
        'Success Stories',
      ],
    };
    final catalog = FeatureCatalog.forRole(role);
    final actions = titles
        .map((title) => catalog.firstWhere((item) => item.title == title))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quick access',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const Text(
              'Role-secured tools',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final feature = actions[index];
              return InkWell(
                onTap: () => onOpen(feature),
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  width: 190,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: feature.color,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(feature.icon, size: 21),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          feature.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_outward_rounded, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
