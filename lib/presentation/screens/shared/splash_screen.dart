import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final AnimationController _progressController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  static const _ink = Color(0xFF171717);
  static const _orange = Color(0xFFFFA63D);
  static const _orangeDeep = Color(0xFFF27A2F);
  static const _cream = Color(0xFFFFF7EC);
  static const _muted = Color(0xFF756F68);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.72, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_cream, Color(0xFFFFE9D1), Color(0xFFFFD4A7)],
            stops: [0, 0.58, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  const Positioned(
                    top: -86,
                    right: -72,
                    child: _SoftCircle(size: 220, color: Color(0x55FFFFFF)),
                  ),
                  const Positioned(
                    left: -88,
                    bottom: 82,
                    child: _SoftCircle(size: 190, color: Color(0x26F27A2F)),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.34,
                    right: 18,
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Color(0x20F27A2F),
                      size: 46,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      compact ? 12 : 18,
                      24,
                      compact ? 12 : 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _fade,
                          child: const _BrandPill(),
                        ),
                        SizedBox(height: compact ? 14 : 22),
                        FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: _slide,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Everything your pet\n'),
                                  TextSpan(
                                    text: 'needs, ',
                                    style: TextStyle(color: _orangeDeep),
                                  ),
                                  const TextSpan(text: 'in one place.'),
                                ],
                              ),
                              style: TextStyle(
                                color: _ink,
                                fontSize: compact ? 34 : 43,
                                height: 1.06,
                                letterSpacing: -1.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        FadeTransition(
                          opacity: _fade,
                          child: Text(
                            'Trusted care, happier pets, and every important moment beautifully connected.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: compact ? 12.5 : 14,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 16),
                        Expanded(
                          child: FadeTransition(
                            opacity: _fade,
                            child: ScaleTransition(
                              scale: _scale,
                              child: _PetHero(
                                controller: _floatController,
                                compact: compact,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 9 : 13),
                        if (!compact) ...[
                          const _FeatureRow(),
                          const SizedBox(height: 14),
                        ],
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _progressController.value,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.7,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  _orangeDeep,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 9),
                        const Center(
                          child: Text(
                            'Preparing a pawfect experience…',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.15,
                            ),
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
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  const _BrandPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 7, 16, 7),
      decoration: BoxDecoration(
        color: _SplashScreenState._ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26171717),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _SplashScreenState._orange,
            child: Icon(Icons.pets_rounded, color: Colors.white, size: 19),
          ),
          SizedBox(width: 10),
          Text(
            'PawfectCare',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetHero extends StatelessWidget {
  const _PetHero({required this.controller, required this.compact});

  final AnimationController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final lift = (controller.value - 0.5) * 8;
        return Transform.translate(offset: Offset(0, lift), child: child);
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            top: compact ? 8 : 14,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB760), Color(0xFFFF8E43)],
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.78),
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33D56B26),
                    blurRadius: 26,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 15,
            top: compact ? 20 : 28,
            child: const _HeroBadge(
              icon: Icons.health_and_safety_rounded,
              label: 'Safe care',
            ),
          ),
          Positioned(
            right: 14,
            top: compact ? 18 : 26,
            child: const _RoundBadge(icon: Icons.favorite_rounded),
          ),
          Positioned.fill(
            top: compact ? 2 : 8,
            bottom: 2,
            child: Image.asset(
              'assets/images/image.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Happy dog and cat',
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.pets_rounded, color: Colors.white, size: 88),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF54A978),
                    size: 17,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Care • Connect • Adopt',
                    style: TextStyle(
                      color: _SplashScreenState._ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEEFFFFFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF54A978), size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _SplashScreenState._ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: _SplashScreenState._orangeDeep, size: 21),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _FeatureChip(
            icon: Icons.medical_services_rounded,
            label: 'Health',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _FeatureChip(icon: Icons.home_rounded, label: 'Adoption'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _FeatureChip(icon: Icons.groups_rounded, label: 'Community'),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: _SplashScreenState._orangeDeep),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SplashScreenState._ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
