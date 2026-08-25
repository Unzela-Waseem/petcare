import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';

// ── Per-page configuration ─────────────────────────────────────────────────────
class _PageData {
  const _PageData({
    required this.title,
    required this.subtitle,
    required this.cardHeading,
    required this.imagePath,
    required this.bgColor,
    required this.accentColor,
    required this.badgeIcon,
    required this.style,
  });

  final String title;
  final String subtitle;
  final String cardHeading;
  final String imagePath;
  final Color bgColor;
  final Color accentColor;
  final IconData badgeIcon;
  final _PageStyle style;
}

enum _PageStyle { classic, purpleCard, orangeCard }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;

  // Page animation controller
  late final AnimationController _pageAnim;

  static const _pages = [
    _PageData(
      title: 'Care that feels\nlike family.',
      subtitle:
          'Everything your companion needs, together in one gentle place.',
      cardHeading: 'Your pet, perfectly cared for',
      imagePath: 'assets/images/pawfect_pet_family_cutout.png',
      bgColor: Color(0xFFFFF5E6),
      accentColor: AppColors.peachLight,
      badgeIcon: Icons.favorite_rounded,
      style: _PageStyle.classic,
    ),
    _PageData(
      title: 'Get your Favourite pets',
      subtitle:
          'Bring your favourite pet to your home. Adopt pet of your choice to get company or entertainment, pets comfort us and give us companionship.',
      cardHeading: '',
      imagePath: 'assets/images/onboarding_dog_purple.png',
      bgColor: Colors.white,
      accentColor: Color(0xFFC48BE8),
      badgeIcon: Icons.pets_rounded,
      style: _PageStyle.purpleCard,
    ),
    _PageData(
      title: 'Homey\nPet \u{1F43E}',
      subtitle: 'Make your bonding relationship between pets & humans',
      cardHeading: 'Take Care Of\nYour Pet',
      imagePath: 'assets/images/onboarding_cat_orange.png',
      bgColor: Color(0xFFFA8F3D),
      accentColor: Color(0xFFFA8F3D),
      badgeIcon: Icons.groups_rounded,
      style: _PageStyle.orangeCard,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageAnim.dispose();
    super.dispose();
  }

  void _onPageChanged(int value) {
    setState(() => _page = value);
    _pageAnim.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pages[_page];
    final isColoredBg = currentPage.style != _PageStyle.classic;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: currentPage.bgColor,
      child: SafeArea(
        child: Stack(
          children: [
            // ── Page content (fullscreen) ─────────────────────
            PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final data = _pages[index];
                switch (data.style) {
                  case _PageStyle.classic:
                    return _ClassicPage(
                      data: data,
                      index: index,
                      animController: _pageAnim,
                      isCurrent: index == _page,
                      onNext: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      ),
                    );
                  case _PageStyle.purpleCard:
                    return _PurpleCardPage(
                      data: data,
                      animController: _pageAnim,
                      isCurrent: index == _page,
                      onNext: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      ),
                    );
                  case _PageStyle.orangeCard:
                    return _OrangeCardPage(
                      data: data,
                      animController: _pageAnim,
                      isCurrent: index == _page,
                      onComplete: widget.onComplete,
                    );
                }
              },
            ),

            // ── Top bar (overlaid on all pages) ──────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(_pages.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: active ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? (isColoredBg ? Colors.white : AppColors.ink)
                                : (isColoredBg
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : AppColors.ink.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onComplete,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isColoredBg
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
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

// ── Classic Page (Page 1) ─────────────────────────────────────────────────────
class _ClassicPage extends StatelessWidget {
  const _ClassicPage({
    required this.data,
    required this.index,
    required this.animController,
    required this.isCurrent,
    required this.onNext,
  });

  final _PageData data;
  final int index;
  final AnimationController animController;
  final bool isCurrent;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;

    final fadeAnim = CurvedAnimation(parent: animController, curve: Curves.easeIn);
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animController, curve: Curves.easeOutCubic));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 52),
              // ── Title row ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: compact ? 34 : 40,
                            height: 1.1,
                          ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: data.accentColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(data.badgeIcon, color: AppColors.orangeDeep, size: 24),
                  ),
                ],
              ),
              // ── Image card ─────────────────────────────────
              Expanded(
                child: _ClassicImageCard(data: data, index: index),
              ),
              const SizedBox(height: 14),
              // ── Info card ──────────────────────────────────
              _ClassicInfoCard(data: data),
              const SizedBox(height: 10),
              // ── Next button ────────────────────────────────
              PawButton(label: 'Next →', onPressed: onNext),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Purple Card Page (Page 2) ─────────────────────────────────────────────────
class _PurpleCardPage extends StatelessWidget {
  const _PurpleCardPage({
    required this.data,
    required this.animController,
    required this.isCurrent,
    required this.onNext,
  });

  final _PageData data;
  final AnimationController animController;
  final bool isCurrent;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final fadeAnim = CurvedAnimation(parent: animController, curve: Curves.easeIn);
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animController, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Container(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Exact reference design as background
              Image.asset(
                data.imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              // Bottom clickable area for 'Next ->'
              Positioned(
                bottom: 24,
                right: 24,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Orange Card Page (Page 3) ─────────────────────────────────────────────────
class _OrangeCardPage extends StatelessWidget {
  const _OrangeCardPage({
    required this.data,
    required this.animController,
    required this.isCurrent,
    required this.onComplete,
  });

  final _PageData data;
  final AnimationController animController;
  final bool isCurrent;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    final fadeAnim = CurvedAnimation(parent: animController, curve: Curves.easeIn);
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animController, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Container(
          color: const Color(0xFFFA8F3D),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Exact reference design as background
              Image.asset(
                data.imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              // Bottom clickable button matching 'Get Started'
              Positioned(
                bottom: 30,
                left: 36,
                right: 36,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: onComplete,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFA8F3D),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFA8F3D).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFFFA8F3D),
                              size: 18,
                            ),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Classic Image card ────────────────────────────────────────────────────────
class _ClassicImageCard extends StatelessWidget {
  const _ClassicImageCard({required this.data, required this.index});
  final _PageData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.accentColor.withValues(alpha: 0.55),
            data.accentColor.withValues(alpha: 0.25),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: data.accentColor.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _DotPatternPainter(data.accentColor)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.contain,
                  semanticLabel: 'A cat and dog together',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Classic Info card ────────────────────────────────────────────────────────
class _ClassicInfoCard extends StatelessWidget {
  const _ClassicInfoCard({required this.data});
  final _PageData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: data.accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.cardHeading,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot pattern painter ───────────────────────────────────────────────────────
class _DotPatternPainter extends CustomPainter {
  _DotPatternPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius = 2.2;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter old) => old.color != color;
}
