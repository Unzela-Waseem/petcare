// lib/presentation/screens/shared/splash_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Animation controllers used in the splash screen.
  late final AnimationController _seq;
  late final AnimationController _bgShift;
  late final AnimationController _glowPulse;
  late final AnimationController _progress;
  late final AnimationController _float;
  late final AnimationController _shimmer;
  late final AnimationController _timerController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOp;
  late final Animation<double> _logoGlow;
  late final Animation<double> _t1Op;
  late final Animation<double> _t1Y;
  late final Animation<double> _t1Sc;
  late final Animation<double> _t2Op;
  late final Animation<double> _t2Y;
  late final Animation<double> _t2Sc;
  late final Animation<double> _t3Op;
  late final Animation<double> _t3Y;
  late final Animation<double> _t3Sc;
  late final Animation<double> _pawOp;
  late final Animation<double> _pawSc;
  late final Animation<double> _chipOp;
  late final Animation<double> _chipY;
  late final Animation<double> _barOp;
  late final Animation<double> _barY;
  late final Animation<double> _bgOff;
  late final Animation<double> _shimX;

  // Particle list.
  late final List<_Particle> _particles;

  // Colors used throughout the splash screen.
  static const Color _ink = Color(0xFF1A1A2E);
  static const Color _orangeDeep = Color(0xFFE8723A);
  static const Color _peach = Color(0xFFF4C28F);
  static const Color _muted = Color(0xFF8E8E9A);
  static const Color _gold = Color(0xFFFFD080);

  @override
  void initState() {
    super.initState();
    _particles = _makeParticles();

    // Main sequence controller drives most UI animations.
    _seq = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    // Background movement.
    _bgShift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Logo glow.
    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Animated progress bar (3‑second loading).
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // Floating particles animation.
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Shimmer animation for title text.
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Timer controller used for the countdown display.
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // Background offset used for gradient animation.
    _bgOff = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_bgShift);

    // Shimmer X movement.
    _shimX = Tween<double>(
      begin: -1.2,
      end: 2.2,
    ).animate(_shimmer);

    // Helper to create tweens with timing.
    _logoScale = _tw(0.0, 1.0, 0.00, 0.16, Curves.elasticOut);
    _logoOp = _tw(0.0, 1.0, 0.00, 0.11, Curves.easeOut);
    _logoGlow = _tw(0.15, 0.55, 0.00, 0.23, Curves.easeInOut);
    _t1Op = _tw(0.0, 1.0, 0.08, 0.23, Curves.easeOut);
    _t1Y = _tw(38.0, 0.0, 0.08, 0.27, Curves.easeOutCubic);
    _t1Sc = _tw(0.88, 1.0, 0.08, 0.27, Curves.easeOutCubic);
    _t2Op = _tw(0.0, 1.0, 0.14, 0.30, Curves.easeOut);
    _t2Y = _tw(38.0, 0.0, 0.14, 0.34, Curves.easeOutCubic);
    _t2Sc = _tw(0.88, 1.0, 0.14, 0.34, Curves.easeOutCubic);
    _t3Op = _tw(0.0, 1.0, 0.20, 0.37, Curves.easeOut);
    _t3Y = _tw(38.0, 0.0, 0.20, 0.41, Curves.easeOutCubic);
    _t3Sc = _tw(0.88, 1.0, 0.20, 0.41, Curves.easeOutCubic);
    _pawOp = _tw(0.0, 1.0, 0.28, 0.44, Curves.easeOut);
    _pawSc = _tw(0.0, 1.0, 0.28, 0.48, Curves.elasticOut);
    _chipOp = _tw(0.0, 1.0, 0.34, 0.50, Curves.easeOut);
    _chipY = _tw(18.0, 0.0, 0.34, 0.52, Curves.easeOutCubic);
    _barOp = _tw(0.0, 1.0, 0.42, 0.58, Curves.easeOut);
    _barY = _tw(28.0, 0.0, 0.42, 0.60, Curves.easeOutCubic);

    // When progress completes, navigate to home.
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });
  }

  // Helper to create a tween animation.
  Animation<double> _tw(double begin, double end, double start, double endT, Curve curve) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _seq, curve: Interval(start, endT, curve: curve)),
    );
  }

  // Navigation to the main app.
  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _seq.dispose();
    _bgShift.dispose();
    _glowPulse.dispose();
    _progress.dispose();
    _float.dispose();
    _shimmer.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final sm = w < 380;

    return AnimatedBuilder(
      animation: _seq,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient.
              AnimatedBuilder(
                animation: _bgOff,
                builder: (_, __) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-0.3 + sin(_bgOff.value * 2 * pi) * 0.15, -1.1),
                        end: Alignment(0.7 + cos(_bgOff.value * 2 * pi) * 0.15, 1.0),
                        colors: const [
                          Color(0xFFFDF8F0),
                          Color(0xFFF9ECDA),
                          Color(0xFFF2D9BA),
                          Color(0xFFE8C49A),
                        ],
                        stops: const [0.0, 0.32, 0.68, 1.0],
                      ),
                    ),
                  );
                },
              ),

              // Soft cloud shapes.
              _CloudShape(left: -40, top: size.height * 0.06, size: 180),
              _CloudShape(right: -30, top: size.height * 0.15, size: 140),
              _CloudShape(left: size.width * 0.3, top: size.height * 0.02, size: 100),

              // Glows.
              _buildGlow(w * 0.75, h * 0.08, w * 0.55, Colors.white.withOpacity(0.18)),
              _buildGlow(-w * 0.10, h * 0.35, w * 0.40, Colors.white.withOpacity(0.12)),
              _buildGlow(w * 0.50, h * 0.55, w * 0.35, const Color(0xFFFFD699).withOpacity(0.10)),

              // Rings.
              _buildRing(w * 0.82, -h * 0.06, w * 0.28, false),
              _buildRing(-w * 0.12, h * 0.18, w * 0.20, true),
              _buildRing(w * 0.60, h * 0.48, w * 0.15, false),

              // Particles.
              ..._particles.map((p) => _ParticleWidget(p: p, ctrl: _float)),

              // Main content.
              Positioned(
                top: h * 0.075,
                left: 28,
                right: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(),
                    SizedBox(height: sm ? 24 : 34),
                    _buildTitleLine('Your pet', _t1Op, _t1Y, _t1Sc, sm, false),
                    _buildTitleLine('deserves', _t2Op, _t2Y, _t2Sc, sm, false),
                    _buildTitleLine('the best', _t3Op, _t3Y, _t3Sc, sm, true),
                    const SizedBox(height: 8),
                    Opacity(opacity: _pawOp.value, child: Transform.scale(scale: _pawSc.value, child: Text('🐾', style: TextStyle(fontSize: sm ? 36 : 44)))),
                    const SizedBox(height: 20),
                    Opacity(opacity: _chipOp.value, child: Transform.translate(offset: Offset(0, _chipY.value), child: _buildChip())),
                  ],
                ),
              ),

              // Bottom bar with progress and timer.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar.
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (_, __) {
                        return Container(
                          height: 4,
                          decoration: BoxDecoration(color: _peach.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progress.value,
                              child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [_orangeDeep, Color(0xFFFFAA44)]))),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Countdown timer.
                        AnimatedBuilder(
                          animation: _timerController,
                          builder: (_, __) {
                            final secondsLeft = ((1.0 - _timerController.value) * 3).ceil();
                            return SizedBox(
                              width: 56,
                              height: 56,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(56, 56),
                                    painter: _RingPainter(color: _peach.withOpacity(0.18), sw: 3),
                                  ),
                                  CustomPaint(
                                    size: const Size(56, 56),
                                    painter: _RingPainter(color: _orangeDeep, sw: 3, prog: _timerController.value, round: true),
                                  ),
                                  Text('$secondsLeft', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
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
                              Text('Made with care for pet lovers', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: _ink, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('v1.0 · PawfectCare', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        // Skip button.
                        GestureDetector(
                          onTap: _navigate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: _ink.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 5))]),
                            child: const Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widgets (unchanged from original).
  Widget _buildGlow(double left, double top, double size, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent]))),
    );
  }

  Widget _buildRing(double left, double top, double size, bool reverse) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, __) {
        final v = reverse ? 1.0 - _float.value : _float.value;
        return Positioned(
          left: left,
          top: top,
          child: Transform.rotate(angle: v * 2 * pi, child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4A050).withOpacity(0.10), width: 1.5)))),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Opacity(
      opacity: _logoOp.value,
      child: AnimatedBuilder(
        animation: _logoGlow,
        builder: (_, __) {
          return Transform.scale(
            scale: _logoScale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: _ink.withOpacity(0.20), blurRadius: 32, offset: const Offset(0, 12)), BoxShadow(color: _gold.withOpacity(_logoGlow.value), blurRadius: 44, spreadRadius: 6)],
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.pets_rounded, color: _gold, size: 20), SizedBox(width: 10), Text('PawfectCare', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5))]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleLine(String text, Animation<double> opacity, Animation<double> y, Animation<double> scale, bool sm, bool accent) {
    final fontSize = sm ? 42.0 : 52.0;
    return Opacity(
      opacity: opacity.value,
      child: Transform.translate(offset: Offset(0, y.value), child: Transform.scale(scale: scale.value, alignment: Alignment.centerLeft, child: AnimatedBuilder(animation: _shimmer, builder: (_, __) => ShaderMask(shaderCallback: (bounds) {
        final width = bounds.width;
        final shimmerPosition = _shimX.value * width;
        return LinearGradient(colors: accent ? const [_ink, _ink, Color(0xFFE8875B), _ink, _ink] : const [_ink, _ink, Color(0xFFD4A050), _ink, _ink], stops: const [0.0, 0.32, 0.50, 0.68, 1.0], transform: _SlidingGradientTransform(shimmerPosition - width * 0.3),).createShader(bounds);
      }, blendMode: BlendMode.srcIn, child: Text(text, style: TextStyle(fontSize: fontSize, height: 1.08, letterSpacing: -2.0, fontWeight: FontWeight.w900, color: _ink)),),),),);
  }

  Widget _buildChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.80)), boxShadow: [BoxShadow(color: const Color(0xFFC9A04C).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: _orangeDeep, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _orangeDeep.withOpacity(0.35), blurRadius: 6)])), const SizedBox(width: 10), Text('Preparing your experience…', style: TextStyle(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w500))]),
    );
  }

  List<_Particle> _makeParticles() {
    final rng = Random(42);
    final icons = [Icons.favorite_rounded, Icons.pets_rounded, Icons.star_rounded, Icons.volunteer_activism_rounded];
    final colors = [const Color(0xFFFF8A65), const Color(0xFFCE93D8), const Color(0xFFFFD54F), const Color(0xFF81C784)];
    return List.generate(18, (i) => _Particle(icon: icons[i % 4], color: colors[i % 4], x: rng.nextDouble(), baseY: 0.9 + rng.nextDouble() * 0.3, size: 10.0 + rng.nextDouble() * 14, speed: 0.06 + rng.nextDouble() * 0.10, drift: (rng.nextDouble() - 0.5) * 0.04, rot: rng.nextDouble() * pi * 2, rotSpd: (rng.nextDouble() - 0.5) * 0.015, alpha: 0.05 + rng.nextDouble() * 0.08));
  }
}

// Particle model and widget definitions remain unchanged.
class _Particle {
  final IconData icon;
  final Color color;
  final double x;
  final double baseY;
  final double size;
  final double speed;
  final double drift;
  final double rot;
  final double rotSpd;
  final double alpha;

  _Particle({required this.icon, required this.color, required this.x, required this.baseY, required this.size, required this.speed, required this.drift, required this.rot, required this.rotSpd, required this.alpha});
}

class _ParticleWidget extends StatelessWidget {
  const _ParticleWidget({required this.p, required this.ctrl});
  final _Particle p;
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final v = ctrl.value;
        final cycle = (v * p.speed * 3) % 1.4 - 0.2;
        final py = p.baseY - cycle;
        final px = p.x + sin(v * 2 * pi + p.rot) * p.drift * 10;
        final rotation = p.rot + v * p.rotSpd * 2 * pi;
        final opacity = py < -0.1 || py > 1.2 ? 0.0 : p.alpha * (1.0 - (py.abs() - 0.3).clamp(0.0, 0.7));
        return Positioned(
          left: px * MediaQuery.sizeOf(context).width,
          top: py * MediaQuery.sizeOf(context).height,
          child: Opacity(opacity: opacity, child: Transform.rotate(angle: rotation, child: Icon(p.icon, size: p.size, color: p.color))),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  _SlidingGradientTransform(this.dx);
  final double dx;
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(dx, 0, 0);
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.sw, this.prog = 1.0, this.round = false});
  final Color color;
  final double sw;
  final double prog;
  final bool round;
  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - sw * 2) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color..strokeWidth = sw..style = PaintingStyle.stroke..strokeCap = round ? StrokeCap.round : StrokeCap.butt;
    if (prog >= 1.0) {
      canvas.drawCircle(center, radius, paint);
    } else {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -pi / 2, 2 * pi * prog, false, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => prog != oldDelegate.prog || color != oldDelegate.color || sw != oldDelegate.sw || round != oldDelegate.round;
}

class _CloudShape extends StatelessWidget {
  const _CloudShape({this.left, this.right, required this.top, required this.size});
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
      child: Container(width: size, height: size, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFffffff).withOpacity(0.2))),
    );
  }
}