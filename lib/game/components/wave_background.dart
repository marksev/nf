import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../wave_rider_game.dart';

/// Draws the scrolling ocean background: sky, sun, stars, clouds, layered waves.
class WaveBackground extends Component with HasGameRef<WaveRiderGame> {
  WaveBackground() : super(priority: 0);

  double _scrollOffset = 0.0;

  @override
  void update(double dt) {
    _scrollOffset += gameRef.scrollSpeed * dt;
    if (_scrollOffset > 800) _scrollOffset -= 800;
  }

  @override
  void render(Canvas canvas) {
    final w = gameRef.size.x;
    final h = gameRef.size.y;
    final waterY = gameRef.getWaterY();

    _drawSky(canvas, w, h, waterY);
    _drawSun(canvas, w, h);
    _drawStars(canvas, w, h * 0.5);
    _drawClouds(canvas, w);
    _drawOceanBody(canvas, w, h, waterY);
    _drawDeepWaterStripes(canvas, w, h, waterY);
    _drawWaveLayer(canvas, w, h, waterY,
        speedFactor: 1.0, amplitude: 28.0, phaseOffset: 0.0,
        color: GameColors.wave1, opacity: 0.72);
    _drawWaveLayer(canvas, w, h, waterY,
        speedFactor: 0.68, amplitude: 18.0, phaseOffset: 200.0,
        color: GameColors.wave2, opacity: 0.50);
    _drawWaveLayer(canvas, w, h, waterY + 6,
        speedFactor: 1.35, amplitude: 10.0, phaseOffset: 90.0,
        color: GameColors.waveFoam, opacity: 0.38);
  }

  void _drawSky(Canvas canvas, double w, double h, double waterY) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, waterY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.skyTop, GameColors.skyBottom],
        ).createShader(Rect.fromLTWH(0, 0, w, waterY)),
    );
  }

  void _drawSun(Canvas canvas, double w, double h) {
    // Soft glow
    canvas.drawCircle(
      Offset(w * 0.84, h * 0.11),
      30,
      Paint()
        ..color = const Color(0xFFFFEB3B).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    // Sun body
    canvas.drawCircle(
      Offset(w * 0.84, h * 0.11),
      20,
      Paint()..color = const Color(0xFFFFF9C4),
    );
    canvas.drawCircle(
      Offset(w * 0.84, h * 0.11),
      14,
      Paint()..color = const Color(0xFFFFEB3B),
    );
  }

  void _drawStars(Canvas canvas, double w, double skyH) {
    // Deterministic star positions using golden-angle spread
    for (int i = 0; i < 28; i++) {
      final sx = (i * 137.508) % w;
      final sy = (i * 73.2 + i * i * 0.5) % (skyH * 0.65);
      final brightness = 0.35 + 0.6 * sin(gameRef.wavePhase * 0.4 + i);
      canvas.drawCircle(
        Offset(sx, sy),
        1.1,
        Paint()..color = Colors.white.withOpacity(brightness),
      );
    }
  }

  void _drawClouds(Canvas canvas, double w) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.72);
    final off = _scrollOffset * 0.14;
    _cloud(canvas, cloudPaint, w * 0.18 - off % w, 22, 42, 16);
    _cloud(canvas, cloudPaint, w * 0.52 - (off * 0.78) % w, 14, 56, 20);
    _cloud(canvas, cloudPaint,
        (w * 0.80 - (off * 0.55) % w + w) % (w + 120) - 60, 32, 34, 13);
  }

  void _cloud(Canvas canvas, Paint p, double cx, double cy, double rw, double rh) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rw * 2, height: rh * 1.5), p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - rw * 0.52, cy + rh * 0.25),
            width: rw * 1.2,
            height: rh),
        p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + rw * 0.5, cy + rh * 0.2),
            width: rw * 1.4,
            height: rh * 1.2),
        p);
  }

  void _drawOceanBody(Canvas canvas, double w, double h, double waterY) {
    canvas.drawRect(
      Rect.fromLTWH(0, waterY, w, h - waterY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.oceanLight, GameColors.oceanDark],
        ).createShader(Rect.fromLTWH(0, waterY, w, h - waterY)),
    );
  }

  void _drawDeepWaterStripes(Canvas canvas, double w, double h, double waterY) {
    const count = 5;
    final stripeH = (h - waterY) / count;
    for (int i = 0; i < count; i++) {
      final alpha = 0.055 * (count - i) / count;
      final stripeOff = (_scrollOffset * (0.28 + i * 0.09)) % 160;
      final paint = Paint()
        ..color = GameColors.waveFoam.withOpacity(alpha)
        ..strokeWidth = 1;
      final y = waterY + 28 + i * stripeH;
      for (double x = -stripeOff; x < w + 80; x += 80) {
        canvas.drawLine(Offset(x, y), Offset(x + 50, y), paint);
      }
    }
  }

  void _drawWaveLayer(
    Canvas canvas,
    double w,
    double h,
    double baseY, {
    required double speedFactor,
    required double amplitude,
    required double phaseOffset,
    required Color color,
    required double opacity,
  }) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    final offset = (_scrollOffset * speedFactor + phaseOffset) % 200;
    final path = Path()..moveTo(-offset, baseY);
    for (double x = -offset; x <= w + 50; x += 4) {
      final y = baseY +
          sin((x + offset) / 60 * pi) * amplitude +
          sin((x + offset) / 30 * pi) * (amplitude * 0.4);
      path.lineTo(x, y);
    }
    path.lineTo(w + 50, h + 10);
    path.lineTo(-offset, h + 10);
    path.close();
    canvas.drawPath(path, paint);
  }
}
