import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/paw_button.dart';

// ── Floating badge configuration ─────────────────────────────────────────
class _FloatingBadge {
  const _FloatingBadge({
    required this.icon,
    this.label,
    this.top,
    this.right,
    this.left,
    this.bottom,
    required this.bgColor,
    this.fgColor = Colors.white,
    this.size = 44,
    this.rotation = 0.0,
  });

  final IconData icon;
  final String? label;
  final double? top;
  final double? right;
  final double? left;
  final double? bottom;
  final Color bgColor;
  final Color fgColor;
  final double size;
  final double rotation;
}

// ── Background blob configuration ────────────────────────────────────────
class _BgBlob {
  const _BgBlob({
    required this.color,
    required this.size,
    this.top,
    this.right,
    this.left,
    this.bottom,
  });

  final Color color;
  final double size;
  final double? top;
  final double? right;
  final double? left;
  final double? bottom;
}

// ── Per-page configuration ──────────────────────────────────────────────
class _PageData {
  const _PageData({
    required this.title,
    required this.subtitle,
    required this.cardHeading,
    required this.imagePath,
    required this.bgColor,
    required this.accentColor,
    required this.badgeIcon,
    required this.badgeIconColor,
    required this.isDarkBg,
    this.imageFit = BoxFit.contain,
    this.imageScale = 1.0,
    this.imagePadding = 16,
    this.floatingBadges = const [],
    this.tags = const [],
    this.cardBorderColor,
    this.bgBlobs = const [],
    this.imageCardColors = const [Color(0xFFFFE5CB), Color(0xFFFFF7EE)],
  });

  final String title;
  final String subtitle;
  final String cardHeading;
  final String imagePath;
  final Color bgColor;
  final Color accentColor;
  final IconData badgeIcon;
  final Color badgeIconColor;
  final bool isDarkBg;
  final BoxFit imageFit;
  final double imageScale;
  final double imagePadding;
  final List<_FloatingBadge> floatingBadges;
  final List<String> tags;
  final Color? cardBorderColor;
  final List<_BgBlob> bgBlobs;
  final List<Color> imageCardColors;
}

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
  bool _imagesPrecached = false;

  late final AnimationController _pageAnim;

  static const _pages = [
    // ── Page 1 ────────────────────────────────────────────────────
    _PageData(
      title: 'Care that feels\nlike family.',
      subtitle:
          'Everything your companion needs, together in one gentle place.',
      cardHeading: 'Your pet, perfectly cared for',
      imagePath: 'assets/images/image.png',
      bgColor: Color(0xFFFFF5E6),
      accentColor: AppColors.peachLight,
      badgeIcon: Icons.favorite_rounded,
      badgeIconColor: AppColors.orangeDeep,
      isDarkBg: false,
      imageScale: 0.94,
      imagePadding: 8,
      imageCardColors: [Color(0xFFFFD8B8), Color(0xFFFFF1E4)],
      floatingBadges: [
        _FloatingBadge(
          icon: Icons.health_and_safety_rounded,
          top: 16,
          left: -10,
          bgColor: Color(0xFF54B788),
          size: 42,
          rotation: -0.10,
        ),
        _FloatingBadge(
          icon: Icons.favorite_rounded,
          label: 'Loved',
          bottom: 22,
          right: -10,
          bgColor: Color(0xFFFF7B52),
          size: 44,
          rotation: 0.08,
        ),
      ],
      tags: ['Health', 'Love', 'Care'],
    ),

    // ── Page 2 ────────────────────────────────────────────────────
    _PageData(
      title: 'Get your\nfavourite pets',
      subtitle:
          'Bring your favourite pet home and give it the love, comfort, and companionship it deserves.',
      cardHeading: 'Find your furry best friend',
      imagePath: 'assets/images/pawfect_pet_family_cutout.png',
      bgColor: Color(0xFFF6ECFC),
      accentColor: Color(0xFFC48BE8),
      badgeIcon: Icons.pets_rounded,
      badgeIconColor: Colors.white,
      isDarkBg: false,

      imageFit: BoxFit.contain,
      imageScale: 0.96,
      imagePadding: 4,
      cardBorderColor: Colors.white,
      imageCardColors: [Color(0xFFE4C7F3), Color(0xFFF8EEFC)],
      floatingBadges: [
        _FloatingBadge(
          icon: Icons.favorite_rounded,
          top: -8,
          right: -8,
          bgColor: Color(0xFFFF6B8A),
          size: 44,
          rotation: 0.18,
        ),
        _FloatingBadge(
          icon: Icons.pets_rounded,
          top: 55,
          left: -12,
          bgColor: Color(0xFFC48BE8),
          size: 40,
          rotation: -0.12,
        ),
        _FloatingBadge(
          icon: Icons.star_rounded,
          label: 'Adopt',
          bottom: 25,
          right: -10,
          bgColor: Color(0xFF9B59B6),
          fgColor: Colors.white,
          size: 44,
          rotation: -0.08,
        ),
      ],
      tags: ['Friendly', 'Loyal', 'Playful'],
      bgBlobs: [
        _BgBlob(color: Color(0x26C48BE8), size: 180, top: -40, right: -30),
        _BgBlob(color: Color(0x33E8B4F8), size: 120, bottom: 100, left: -40),
      ],
    ),

    // ── Page 3 ────────────────────────────────────────────────────
    _PageData(
      title: 'Homey\nPet \u{1F43E}',
      subtitle: 'Build a bond between your pets and the people who love them.',
      cardHeading: 'Take care of your pet',
      imagePath: 'assets/images/onboarding_cat_studio.png',
      bgColor: Color(0xFFFA8F3D),
      accentColor: Colors.white,
      badgeIcon: Icons.groups_rounded,
      badgeIconColor: Color(0xFFFA8F3D),
      isDarkBg: true,
      imageFit: BoxFit.contain,
      imageScale: 0.96,
      imagePadding: 0,
      cardBorderColor: Color(0x59FFFFFF),
      imageCardColors: [Color(0xFFFFBE7B), Color(0xFFFFE0B2)],
      floatingBadges: [
        _FloatingBadge(
          icon: Icons.home_rounded,
          top: -8,
          right: -8,
          bgColor: Colors.white,
          fgColor: Color(0xFFFA8F3D),
          size: 44,
          rotation: 0.14,
        ),
        _FloatingBadge(
          icon: Icons.favorite_rounded,
          bottom: 65,
          left: -12,
          bgColor: Color(0xEBFFFFFF),
          fgColor: Color.fromARGB(255, 163, 81, 71),
          size: 38,
          rotation: 0.10,
        ),
        _FloatingBadge(
          icon: Icons.auto_awesome_rounded,
          label: 'Love',
          bottom: 18,
          right: -10,
          bgColor: Color(0xFFFFD93D),
          fgColor: Color(0xFF8B6914),
          size: 44,
          rotation: -0.14,
        ),
      ],
      tags: ['Cozy', 'Loving', 'Warm'],
      bgBlobs: [
        _BgBlob(color: Color(0x1AFFFFFF), size: 200, top: -50, left: -50),
        _BgBlob(color: Color(0x26FFD93D), size: 140, bottom: 80, right: -35),
      ],
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached) return;
    _imagesPrecached = true;
    for (final page in _pages) {
      precacheImage(AssetImage(page.imagePath), context);
    }
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

  void _next() {
    if (_page == _pages.length - 1) {
      widget.onComplete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pages[_page];
    final isColoredBg = currentPage.isDarkBg;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: currentPage.bgColor,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final data = _pages[index];
                final isLast = index == _pages.length - 1;
                return _OnboardPage(
                  data: data,
                  animController: _pageAnim,
                  buttonLabel: isLast ? 'Get Started' : 'Next →',
                  onNext: _next,
                );
              },
            ),

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
                                      ? Color(0x66FFFFFF)
                                      : Color(0x26111B21)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    if (_page != _pages.length - 1)
                      TextButton(
                        onPressed: widget.onComplete,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: isColoredBg
                                ? Color(0xD9FFFFFF)
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

// ── Shared onboarding page layout ──────────────────────────────────────
class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.data,
    required this.animController,
    required this.buttonLabel,
    required this.onNext,
  });

  final _PageData data;
  final AnimationController animController;
  final String buttonLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;

    final fadeAnim = CurvedAnimation(
      parent: animController,
      curve: Curves.easeIn,
    );
    final slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: animController, curve: Curves.easeOutCubic),
        );

    final titleColor = data.isDarkBg ? Colors.white : AppColors.ink;

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Stack(
          children: [
            ...data.bgBlobs.map(
              (blob) => Positioned(
                top: blob.top,
                right: blob.right,
                left: blob.left,
                bottom: blob.bottom,
                child: Container(
                  width: blob.size,
                  height: blob.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: blob.color,
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 52),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontSize: compact ? 34 : 40,
                                  height: 1.1,
                                  color: titleColor,
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: data.isDarkBg
                                ? Color(0xE6FFFFFF)
                                : data.accentColor,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            data.badgeIcon,
                            color: data.badgeIconColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _OnboardImageCard(data: data),
                          ...data.floatingBadges.map(
                            (b) => _FloatingBadgeWidget(badge: b),
                          ),
                        ],
                      ),
                    ),

                    if (data.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _TagsRow(
                        tags: data.tags,
                        accentColor: data.accentColor,
                        isDarkBg: data.isDarkBg,
                      ),
                    ],

                    const SizedBox(height: 14),

                    _OnboardInfoCard(data: data),

                    const SizedBox(height: 10),

                    PawButton(label: buttonLabel, onPressed: onNext),

                    const SizedBox(height: 24),
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

// ── Onboard image card ─────────────────────────────────────────────────
class _OnboardImageCard extends StatelessWidget {
  const _OnboardImageCard({required this.data});
  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final dotColor = data.isDarkBg ? Colors.white : data.accentColor;
    final cardColors = data.imageCardColors;
    final shadowColor = data.isDarkBg ? Color(0x2E000000) : Color(0x80ACCEA8);

    final hasBorder = data.cardBorderColor != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardColors,
        ),
        border: hasBorder
            ? Border.all(color: data.cardBorderColor!, width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(hasBorder ? 30 : 32),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _DotPatternPainter(dotColor)),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  data.imagePadding,
                  data.imagePadding,
                  data.imagePadding,
                  0,
                ),
                child: ClipRect(
                  child: Transform.scale(
                    scale: data.imageScale,
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      data.imagePath,
                      fit: data.imageFit,
                      alignment: Alignment.bottomCenter,
                      filterQuality: FilterQuality.high,
                      semanticLabel: data.cardHeading,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(
                          Icons.pets_rounded,
                          size: 64,
                          color: data.accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating badge widget ───────────────────────────────────────────────
class _FloatingBadgeWidget extends StatelessWidget {
  const _FloatingBadgeWidget({required this.badge});
  final _FloatingBadge badge;

  @override
  Widget build(BuildContext context) {
    final hasLabel = badge.label != null;

    return Positioned(
      top: badge.top,
      right: badge.right,
      left: badge.left,
      bottom: badge.bottom,
      child: Transform.rotate(
        angle: badge.rotation,
        child: Container(
          decoration: BoxDecoration(
            color: badge.bgColor,
            shape: hasLabel ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: hasLabel ? BorderRadius.circular(20) : null,
            boxShadow: [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          constraints: hasLabel
              ? null
              : BoxConstraints.tight(Size(badge.size, badge.size)),
          padding: hasLabel
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : null,
          alignment: Alignment.center,
          child: hasLabel
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badge.icon, color: badge.fgColor, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      badge.label!,
                      style: TextStyle(
                        color: badge.fgColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                )
              : Icon(badge.icon, color: badge.fgColor, size: 20),
        ),
      ),
    );
  }
}

// ── Tag pills row ───────────────────────────────────────────────────────
class _TagsRow extends StatelessWidget {
  const _TagsRow({
    required this.tags,
    required this.accentColor,
    required this.isDarkBg,
  });

  final List<String> tags;
  final Color accentColor;
  final bool isDarkBg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tags.map((tag) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isDarkBg ? Color(0x33FFFFFF) : Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkBg
                  ? Color(0x4DFFFFFF)
                  : accentColor.withValues(alpha: 0.42),
              width: 1.2,
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              color: isDarkBg ? Colors.white : AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Onboard info card ───────────────────────────────────────────────────
class _OnboardInfoCard extends StatelessWidget {
  const _OnboardInfoCard({required this.data});
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
            color: Color(0x0F000000),
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
              color: data.isDarkBg ? data.bgColor : data.accentColor,
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot pattern painter ─────────────────────────────────────────────────
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
