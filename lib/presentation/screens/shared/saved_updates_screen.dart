import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/care_models.dart';
import '../../../domain/models/user_role.dart';
import '../adoption/adoption_screen.dart';
import '../appointments/appointments_screen.dart';
import '../content/catalog_screens.dart';

class SavedUpdatesScreen extends StatelessWidget {
  const SavedUpdatesScreen({
    required this.user,
    required this.services,
    super.key,
  });
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: switch (user.role) {
      UserRole.petOwner => _OwnerSaved(user: user, services: services),
      UserRole.veterinarian => _VetFollowUps(user: user, services: services),
      UserRole.shelterAdmin => _ShelterPriority(user: user, services: services),
    },
  );
}

class _OwnerSaved extends StatelessWidget {
  const _OwnerSaved({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
    children: [
      Text('Your favorites', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 6),
      const Text(
        'Saved products and care guides stay private to your account.',
      ),
      const SizedBox(height: 22),
      StreamBuilder<Set<String>>(
        stream: services.care.watchWishlist(user.uid),
        builder: (context, savedSnapshot) => StreamBuilder<List<ProductItem>>(
          stream: services.care.watchProducts(),
          builder: (context, productSnapshot) {
            final saved = savedSnapshot.data ?? const <String>{};
            final products = (productSnapshot.data ?? const <ProductItem>[])
                .where((item) => saved.contains(item.id))
                .toList();
            return _SavedGroup(
              title: 'Wishlist',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.yellow,
              items: products.map((item) => item.name).toList(),
              onOpen: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => StoreScreen(user: user, services: services),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 14),
      StreamBuilder<Set<String>>(
        stream: services.care.watchBookmarks(user.uid),
        builder: (context, savedSnapshot) => StreamBuilder<List<BlogArticle>>(
          stream: services.care.watchBlogs(),
          builder: (context, articleSnapshot) {
            final saved = savedSnapshot.data ?? const <String>{};
            final articles = (articleSnapshot.data ?? const <BlogArticle>[])
                .where((item) => saved.contains(item.id))
                .toList();
            return _SavedGroup(
              title: 'Bookmarked care tips',
              icon: Icons.bookmark_outline_rounded,
              color: AppColors.peachLight,
              items: articles.map((item) => item.title).toList(),
              onOpen: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CareTipsScreen(user: user, services: services),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _VetFollowUps extends StatelessWidget {
  const _VetFollowUps({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<CareAppointment>>(
    stream: services.care.watchAppointments(user),
    builder: (context, snapshot) {
      final items = (snapshot.data ?? const <CareAppointment>[])
          .where(
            (item) =>
                item.status == AppointmentStatus.pending ||
                item.status == AppointmentStatus.confirmed,
          )
          .toList();
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: [
          Text(
            'Clinical follow-ups',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          const Text('Upcoming authorized appointments that need attention.'),
          const SizedBox(height: 22),
          if (items.isEmpty)
            const Text('No pending clinical follow-ups.')
          else
            ...items.map(
              (item) => _SimpleTile(
                title: item.petName,
                subtitle:
                    '${DateFormat.yMMMd().add_jm().format(item.dateTime)} · ${item.status.label}',
                color: AppColors.mint,
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AppointmentsScreen(user: user, services: services),
              ),
            ),
            child: const Text('Open Clinical Schedule'),
          ),
        ],
      );
    },
  );
}

class _ShelterPriority extends StatelessWidget {
  const _ShelterPriority({required this.user, required this.services});
  final AppUser user;
  final AppServices services;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<AdoptionRequest>>(
    stream: services.care.watchAdoptionRequests(user),
    builder: (context, snapshot) {
      final items = (snapshot.data ?? const <AdoptionRequest>[])
          .where((item) => item.status == RequestStatus.pending)
          .toList();
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: [
          Text(
            'Priority requests',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          const Text('Pending adoption applications for your shelter.'),
          const SizedBox(height: 22),
          if (items.isEmpty)
            const Text('No adoption requests need review.')
          else
            ...items.map(
              (item) => _SimpleTile(
                title: '${item.ownerName} → ${item.petName}',
                subtitle: item.message,
                color: AppColors.peachLight,
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AdoptionRequestsScreen(user: user, services: services),
              ),
            ),
            child: const Text('Review Requests'),
          ),
        ],
      );
    },
  );
}

class _SavedGroup extends StatelessWidget {
  const _SavedGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.onOpen,
  });
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onOpen,
    borderRadius: BorderRadius.circular(24),
    child: Ink(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.surface, child: Icon(icon)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  items.isEmpty
                      ? 'Nothing saved yet.'
                      : items.take(3).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    ),
  );
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle),
      ],
    ),
  );
}
