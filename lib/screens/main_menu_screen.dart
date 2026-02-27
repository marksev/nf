import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/high_score_manager.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _titleCtrl;
  late final Animation<double> _titleScale;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _titleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _titleScale = CurvedAnimation(
      parent: _titleCtrl,
      curve: Curves.elasticOut,
    );

    _loadBest();
  }

  Future<void> _loadBest() async {
    final hs = await HighScoreManager.getHighScore();
    if (mounted) setState(() => _highScore = hs);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const GameScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    ).then((_) => _loadBest());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _waveCtrl,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            // Animated ocean background
            CustomPaint(painter: _MenuOceanPainter(_waveCtrl.value)),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Title ──────────────────────────────────
                  ScaleTransition(
                    scale: _titleScale,
                    child: Column(
                      children: [
                        _titleText('WAVE', Colors.white),
                        _titleText('RIDER', GameColors.coinGold),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'Surf. Jump. Survive.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── High-score badge ────────────────────────
                  if (_highScore > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 22),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: GameColors.coinGold, width: 1.5),
                      ),
                      child: Text(
                        'BEST  $_highScore',
                        style: const TextStyle(
                          color: GameColors.coinGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                  // ── Play button ─────────────────────────────
                  GestureDetector(
                    onTap: _startGame,
                    child: Container(
                      width: 200,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF00838F)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'PLAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Tap the screen to jump over obstacles',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 68,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 8,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 14,
            offset: const Offset(3, 4),
          ),
        ],
      ),
    );
  }
}

// ── Animated ocean CustomPainter ─────────────────────────────────────────────

class _MenuOceanPainter extends CustomPainter {
  final double t;
  _MenuOceanPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final skyH = h * 0.50;

    // Sky gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1628), Color(0xFF1565C0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Stars
    for (int i = 0; i < 32; i++) {
      final sx = (i * 137.508) % w;
      final sy = (i * 73.2 + i * i * 0.5) % (skyH * 0.72);
      final alpha = 0.35 + 0.60 * sin(t * pi * 2 + i);
      canvas.drawCircle(Offset(sx, sy), 1.1,
          Paint()..color = Colors.white.withOpacity(alpha));
    }

    // Sun
    canvas.drawCircle(Offset(w * 0.84, h * 0.10), 22,
        Paint()..color = const Color(0xFFFFF9C4));
    canvas.drawCircle(Offset(w * 0.84, h * 0.10), 14,
        Paint()..color = const Color(0xFFFFEB3B));

    // Ocean base
    canvas.drawRect(
      Rect.fromLTWH(0, skyH, w, h - skyH),
      Paint()..color = const Color(0xFF0D47A1),
    );

    // Main wave
    _drawWave(canvas, w, h, skyH, t * 2, 20, const Color(0xFF1976D2), 0.85);
    _drawWave(canvas, w, h, skyH - 5, t * 2.5, 11, const Color(0xFFBBDEFB), 0.35);
  }

  void _drawWave(Canvas canvas, double w, double h, double baseY,
      double speed, double amp, Color color, double opacity) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, baseY);
    for (double x = 0; x <= w; x += 4) {
      final y =
          baseY + sin((x / 80 + speed) * pi) * amp + sin((x / 40 + speed) * pi) * (amp * 0.4);
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MenuOceanPainter old) => true;
}
