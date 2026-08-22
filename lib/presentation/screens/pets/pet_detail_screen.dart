import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';

class PetDetailScreen extends StatefulWidget {
  const PetDetailScreen({super.key});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool _favorite = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 355,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.peach,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(7),
              child: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(7),
                child: CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: IconButton(
                    tooltip: _favorite ? 'Remove favorite' : 'Add favorite',
                    onPressed: () => setState(() => _favorite = !_favorite),
                    icon: Icon(
                      _favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _favorite ? AppColors.danger : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.peach),
                  Positioned(
                    right: -40,
                    bottom: 22,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.orangeDeep.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: 80,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(35, 55, 20, 0),
                    child: Image.asset(
                      'assets/images/pawfect_pet_family_cutout.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pet name: Luna',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Healthy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        SizedBox(width: 5),
                        Text('City Care Clinic · 0.9 km nearby'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      children: [
                        Expanded(
                          child: _PetFact(
                            label: 'Female',
                            caption: 'Sex',
                            color: AppColors.lavender,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _PetFact(
                            label: '3 years',
                            caption: 'Age',
                            color: AppColors.yellow,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _PetFact(
                            label: 'Husky',
                            caption: 'Breed',
                            color: AppColors.mint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'About Luna',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Luna is a snow-loving sweetheart who enjoys long walks, puzzle toys, and quiet evenings with her people. Her care plan is shared only with her owner and assigned veterinarian.',
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.peachLight,
                            child: Icon(
                              Icons.vaccines_outlined,
                              color: AppColors.orangeDeep,
                            ),
                          ),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Next care reminder',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 3),
                                Text('Rabies booster · due in 7 days'),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.ink,
                child: IconButton(
                  tooltip: 'Call veterinarian',
                  onPressed: () => _notice(
                    context,
                    'Calling is available after clinic contact setup.',
                  ),
                  icon: const Icon(Icons.call_outlined, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PawButton(
                  label: 'Book Care',
                  onPressed: () => _notice(
                    context,
                    'Choose a veterinarian and time from Appointments.',
                  ),
                ),
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
