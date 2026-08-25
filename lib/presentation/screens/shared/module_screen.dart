import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';
import 'feature_catalog.dart';

class ModuleScreen extends StatefulWidget {
  const ModuleScreen({required this.feature, super.key});

  final FeatureAction feature;

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(widget.feature.title)
        .where(
          (item) =>
              item.title.toLowerCase().contains(_query.toLowerCase()) ||
              item.detail.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.feature.title),
        actions: [
          IconButton(
            tooltip: 'More options',
            onPressed: () =>
                _notice(context, 'Filters are ready for Firebase-backed data.'),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.feature.title.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: const Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.feature.subtitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(_privacyCopy(widget.feature.title)),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No matching results.'))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final colors = [
                            AppColors.peachLight,
                            AppColors.mint,
                            AppColors.lavender,
                            AppColors.yellow,
                          ];
                          return InkWell(
                            onTap: () => _showDetails(context, item),
                            borderRadius: BorderRadius.circular(24),
                            child: Ink(
                              padding: const EdgeInsets.all(17),
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      widget.feature.icon,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(item.detail),
                                      ],
                                    ),
                                  ),
                                  if (item.status != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface.withValues(
                                          alpha: 0.75,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        item.status!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (widget.feature.canCreate) ...[
                const SizedBox(height: 14),
                PawButton(
                  label: _actionLabel(widget.feature.title),
                  icon: Icons.add_rounded,
                  onPressed: () => _notice(
                    context,
                    'The secure ${widget.feature.title.toLowerCase()} form is ready for Firebase configuration.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, _ModuleItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.feature.icon, size: 34, color: AppColors.orangeDeep),
              const SizedBox(height: 14),
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(item.detail),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Access is checked against your signed-in identity and resource relationship.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _notice(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  String _privacyCopy(String title) {
    if (title.contains('Medical') ||
        title.contains('Patient') ||
        title.contains('Health')) {
      return 'Protected records are visible only to the pet owner and assigned veterinarian.';
    }
    if (title.contains('Adoption') || title.contains('Shelter')) {
      return 'Requests stay between the applicant and the responsible shelter.';
    }
    return 'Results are scoped to your role and permissions.';
  }

  String _actionLabel(String title) => switch (title) {
    'Appointments' => 'Book Appointment',
    'Adoption' => 'Start Adoption Request',
    'Medical Records' => 'Add Clinical Record',
    'Calendar' => 'Add Availability',
    'Pet Listings' => 'Add Pet Listing',
    'Success Stories' => 'Create Story',
    'Contact & Feedback' => 'Send a Message',
    _ => 'Add New',
  };

  List<_ModuleItem> _itemsFor(String title) => switch (title) {
    'Health Records' || 'Medical Records' || 'Patient History' => const [
      _ModuleItem(
        'Annual wellness exam',
        'Dr. Maya Chen · 12 Aug 2026',
        'Complete',
      ),
      _ModuleItem(
        'Rabies vaccination',
        'Next dose due 04 Nov 2026',
        'Upcoming',
      ),
      _ModuleItem(
        'Allergy care plan',
        'Seasonal pollen · treatment active',
        'Active',
      ),
    ],
    'Appointments' || "Today's Appointments" || 'Calendar' => const [
      _ModuleItem(
        'Luna · Wellness visit',
        '09:30 · Dr. Maya Chen',
        'Confirmed',
      ),
      _ModuleItem('Milo · Follow-up', '11:15 · City Care Clinic', 'Pending'),
      _ModuleItem('Available afternoon', '14:00–17:30 · 4 open slots', 'Open'),
    ],
    'Pet Store' => const [
      _ModuleItem('Everyday nutrition', 'Balanced adult food · from \$24'),
      _ModuleItem('Gentle grooming kit', 'Brush, shampoo, and paw balm · \$32'),
      _ModuleItem('Enrichment toys', 'Three boredom-busting favorites · \$18'),
    ],
    'Care Tips' => const [
      _ModuleItem('A calmer first vet visit', 'Training · 6 min read'),
      _ModuleItem('Build a balanced bowl', 'Nutrition · 8 min read'),
      _ModuleItem('Pet first-aid essentials', 'First Aid · 10 min read'),
    ],
    'Adoption' || 'Pet Listings' => const [
      _ModuleItem(
        'Coco · Labrador mix',
        '2 years · gentle and social',
        'Available',
      ),
      _ModuleItem(
        'Pepper · Tabby cat',
        '1 year · playful indoor companion',
        'Available',
      ),
      _ModuleItem('Nori · Beagle', '3 years · family friendly', 'Pending'),
    ],
    'Adoption Requests' => const [
      _ModuleItem(
        'Jamie → Coco',
        'Submitted today · reference checked',
        'Review',
      ),
      _ModuleItem(
        'Sam → Pepper',
        'Submitted yesterday · home visit set',
        'Pending',
      ),
      _ModuleItem('Taylor → Nori', 'Approved 18 Aug', 'Approved'),
    ],
    'Assigned Pets' || 'My Pets' => const [
      _ModuleItem('Luna', 'Siberian Husky · 3 years', 'Healthy'),
      _ModuleItem('Milo', 'Orange Tabby · 2 years', 'Due soon'),
    ],
    'Success Stories' => const [
      _ModuleItem('Home at last: Coco', 'Published · 1,240 reads', 'Live'),
      _ModuleItem('Pepper meets her family', 'Draft saved 20 Aug', 'Draft'),
    ],
    'Volunteer Requests' => const [
      _ModuleItem('Weekend dog walking', 'Aisha Khan · Saturdays', 'New'),
      _ModuleItem('Foster support', 'Daniel Lee · Small dogs', 'Review'),
    ],
    'Contact Messages' || 'Contact & Feedback' => const [
      _ModuleItem('Shelter visit question', 'Received 20 minutes ago', 'New'),
      _ModuleItem(
        'Nutrition workshop',
        'Community suggestion · yesterday',
        'Open',
      ),
      _ModuleItem('Nearby locations', '3 vets and 2 shelters near you'),
    ],
    'Notifications' => const [
      _ModuleItem(
        'Vaccination due soon',
        'Luna’s booster is due in 7 days',
        'Today',
      ),
      _ModuleItem(
        'Appointment confirmed',
        'Dr. Maya Chen · Friday at 09:30',
        'Today',
      ),
      _ModuleItem(
        'Adoption request updated',
        'Coco’s shelter reviewed your request',
        'Yesterday',
      ),
    ],
    _ => const [
      _ModuleItem('PawfectCare item', 'Secure role-scoped information'),
    ],
  };
}

class _ModuleItem {
  const _ModuleItem(this.title, this.detail, [this.status]);
  final String title;
  final String detail;
  final String? status;
}
