import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Pet family glides left → right across screen, looping.
  late final AnimationController _runController;
  late final Animation<double> _dogX; // 0.0 → 1.0 (screen width fraction)

  // Dog bounces up/down while running
  late final AnimationController _bounceController;
  late final Animation<double> _dogY;

  // Title + tagline fade in once
  late final AnimationController _fadeController;
  late final Animation<double> _fadeOpacity;
  late final Animation<Offset> _titleSlide;

  // Matches the minimum splash duration in AuthController.
  late final AnimationController _timerController;

  // Paw print trail — positions recorded as dog runs
  final List<_PawPrint> _pawPrints = [];
  double _lastPawX = -1;

  @override
  void initState() {
    super.initState();

    // ── Running (horizontal) ─────────────────────────────────
    _runController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _dogX = Tween<double>(
      begin: -0.15,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _runController, curve: Curves.linear));

    // ── Bounce (vertical) ────────────────────────────────────
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..repeat(reverse: true);

    _dogY = Tween<double>(begin: 0, end: -18).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // ── Fade in title ────────────────────────────────────────
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeOpacity = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    // ── Three-second loading countdown ──────────────────────
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // ── Generate paw prints as dog runs ─────────────────────
    _runController.addListener(_maybeAddPaw);
  }

  void _maybeAddPaw() {
    final x = _dogX.value;
    // Drop a paw every ~12% of screen travel
    if ((x - _lastPawX).abs() > 0.12) {
      _lastPawX = x;
      if (x > 0.05 && x < 1.0) {
        setState(() {
          _pawPrints.add(_PawPrint(x: x, createdAt: DateTime.now()));
          // Keep only the last 8 paw prints
          if (_pawPrints.length > 8) _pawPrints.removeAt(0);
        });
      }
    }
  }

  @override
  void dispose() {
    _runController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dogSize = size.width * 0.30; // dog image width
    // Ground line where dog runs (roughly 55% down screen)
    final groundY = size.height * 0.55;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF5E6),
                  Color(0xFFFFE4BB),
                  Color(0xFFFFCF85),
                ],
              ),
            ),
          ),

          // ── Soft cloud shapes ──────────────────────────────
          _CloudShape(left: -40, top: size.height * 0.06, size: 180),
          _CloudShape(right: -30, top: size.height * 0.15, size: 140),
          _CloudShape(
            left: size.width * 0.3,
            top: size.height * 0.02,
            size: 100,
          ),

          // ── Ground strip ──────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: groundY + dogSize * 0.72,
            child: Container(
              height: size.height * 0.45,
              decoration: const BoxDecoration(
                color: Color(0xFFE8C47A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
            ),
          ),

          // ── Grass dots on ground ───────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: groundY + dogSize * 0.72 - 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                22,
                (i) => Container(
                  width: 3,
                  height: i.isEven ? 10 : 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8A448),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // ── Paw print trail ───────────────────────────────
          ..._pawPrints.map((paw) {
            final age = DateTime.now()
                .difference(paw.createdAt)
                .inMilliseconds
                .toDouble();
            final opacity = (1.0 - (age / 3000)).clamp(0.0, 0.55);
            return Positioned(
              left: size.width * paw.x - 12,
              top: groundY + dogSize * 0.65,
              child: Opacity(
                opacity: opacity,
                child: const Icon(
                  Icons.pets,
                  size: 20,
                  color: Color(0xFFB87333),
                ),
              ),
            );
          }),

          // ── Running dog ───────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_runController, _bounceController]),
            builder: (context, _) {
              return Positioned(
                left: _dogX.value * size.width - dogSize * 0.3,
                top: groundY + _dogY.value - dogSize * 0.8,
                child: Image.asset(
                  'assets/images/pawfect_pet_family_cutout.png',
                  width: dogSize,
                  height: dogSize,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),

          // ── Title section (upper half) ────────────────────
          Positioned(
            top: size.height * 0.1,
            left: 28,
            right: 28,
            child: SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _fadeOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App icon pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pets_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'PawfectCare',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Big headline
                    Text(
                      'Your pet\ndeserves\nthe best!',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: size.width < 380 ? 38 : 44,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading your experience…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom: countdown + tagline ───────────────────
          Positioned(
            left: 28,
            right: 28,
            bottom: 36,
            child: FadeTransition(
              opacity: _fadeOpacity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Timer
                  AnimatedBuilder(
                    animation: _timerController,
                    builder: (context, _) {
                      final secondsLeft = ((1.0 - _timerController.value) * 3)
                          .ceil();
                      final progress = 1.0 - _timerController.value;
                      return SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 3.5,
                              color: AppColors.peach.withValues(alpha: 0.45),
                            ),
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3.5,
                              strokeCap: StrokeCap.round,
                              color: AppColors.orangeDeep,
                            ),
                            Text(
                              '$secondsLeft',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Made with care for pet lovers',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                fontSize: 13,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v1.0 · PawfectCare',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
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

// ── Cloud shape helper ─────────────────────────────────────────────────────────
class _CloudShape extends StatelessWidget {
  const _CloudShape({
    this.left,
    this.right,
    required this.top,
    required this.size,
  });

  final double? left;
  final double? right;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        width: size,
        height: size * 0.55,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}

// ── Paw print data ─────────────────────────────────────────────────────────────
class _PawPrint {
  _PawPrint({required this.x, required this.createdAt});
  final double x;
  final DateTime createdAt;
}
