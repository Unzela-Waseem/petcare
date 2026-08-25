import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _content = [
    (
      title: 'Care that feels\nlike family.',
      subtitle:
          'Everything your companion needs, together in one gentle place.',
    ),
    (
      title: 'Health, always\nwithin reach.',
      subtitle:
          'Stay ahead of appointments, vaccines, records, and daily wellbeing.',
    ),
    (
      title: 'More happy\ntails ahead.',
      subtitle:
          'Connect with trusted vets and shelters through one secure experience.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onComplete,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemCount: _content.length,
                    itemBuilder: (context, index) {
                      final item = _content[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(fontSize: compact ? 37 : 44),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 17,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.peachLight,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.pets_rounded,
                                    color: AppColors.orangeDeep,
                                    size: 25,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Center(
                                child: Image.asset(
                                  'assets/images/pawfect_pet_family_cutout.png',
                                  fit: BoxFit.contain,
                                  semanticLabel:
                                      'A cat and dog waiting together',
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(compact ? 18 : 22),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x10000000),
                                    blurRadius: 28,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    index == 0
                                        ? 'Your pet, perfectly cared for'
                                        : index == 1
                                        ? 'Healthy habits made simple'
                                        : 'A community built on care',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item.subtitle),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
                  child: Row(
                    children: [
                      ...List.generate(
                        _content.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: _page == index ? 25 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: _page == index
                                ? AppColors.ink
                                : AppColors.ink.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: PawButton(
                          label: _page == _content.length - 1
                              ? 'Get Started'
                              : 'Next',
                          onPressed: () {
                            if (_page == _content.length - 1) {
                              widget.onComplete();
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

