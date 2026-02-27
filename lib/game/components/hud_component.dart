import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../wave_rider_game.dart';

/// Heads-up display rendered on top of everything (priority 20).
/// Uses raw canvas drawing so it always appears at fixed screen positions.
class HudComponent extends Component with HasGameRef<WaveRiderGame> {
  HudComponent() : super(priority: 20);

  @override
  void render(Canvas canvas) {
    final p = GameConstants.hudPadding;
    final sz = gameRef.size;

    _drawScorePanel(canvas, sz, p);
    _drawLives(canvas, sz, p);
    _drawSpeedIndicator(canvas, sz, p);
  }

  // ── Score ────────────────────────────────────────────────

  void _drawScorePanel(Canvas canvas, Vector2 sz, double p) {
    final score = gameRef.score;
    final best = gameRef.highScore;

    // Background pill
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(sz.x * 0.5 - 88, p - 4, 176, 38),
      const Radius.circular(19),
    );
    canvas.drawRRect(bgRect, Paint()..color = GameColors.hudBg);

    // Score value
    _drawText(
      canvas,
      '$score',
      Offset(sz.x * 0.5, p + 2),
      fontSize: GameConstants.hudFontSize + 2,
      color: GameColors.scoreGold,
      bold: true,
      centerX: true,
    );

    // Best: label (smaller, below)
    if (best > 0) {
      _drawText(
        canvas,
        'BEST: $best',
        Offset(sz.x * 0.5, p + 23),
        fontSize: 10,
        color: Colors.white60,
        bold: false,
        centerX: true,
      );
    }
  }

  // ── Lives ────────────────────────────────────────────────

  void _drawLives(Canvas canvas, Vector2 sz, double p) {
    const hs = GameConstants.heartSize;
    const gap = 6.0;
    final totalW = GameConstants.maxLives * (hs + gap) - gap;
    double x = sz.x - p - totalW;
    for (int i = 0; i < GameConstants.maxLives; i++) {
      _drawHeart(canvas, Offset(x, p), hs, filled: i < gameRef.lives);
      x += hs + gap;
    }
  }

  void _drawHeart(Canvas canvas, Offset origin, double size, {required bool filled}) {
    final cx = origin.dx + size / 2;
    final cy = origin.dy + size * 0.35;
    final r = size * 0.28;
    final color = filled ? GameColors.heartRed : GameColors.heartEmpty;

    // Simple heart via two arcs + a bottom V-point
    final path = Path()
      ..moveTo(cx, origin.dy + size * 0.28)
      ..cubicTo(cx, origin.dy, cx - r * 2, origin.dy, cx - r * 2, cy)
      ..cubicTo(cx - r * 2, cy + r * 1.5, cx, cy + r * 2.2, cx, cy + r * 2.5)
      ..cubicTo(cx, cy + r * 2.2, cx + r * 2, cy + r * 1.5, cx + r * 2, cy)
      ..cubicTo(cx + r * 2, origin.dy, cx, origin.dy, cx, origin.dy + size * 0.28)
      ..close();

    if (filled) {
      canvas.drawPath(path, Paint()..color = color);
      // Shine
      canvas.drawCircle(
        Offset(cx - r * 0.52, origin.dy + size * 0.18),
        r * 0.38,
        Paint()..color = Colors.white.withOpacity(0.45),
      );
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  // ── Speed ribbon ─────────────────────────────────────────

  void _drawSpeedIndicator(Canvas canvas, Vector2 sz, double p) {
    final progress = ((gameRef.scrollSpeed - GameConstants.initialSpeed) /
            (GameConstants.maxSpeed - GameConstants.initialSpeed))
        .clamp(0.0, 1.0);
    if (progress < 0.01) return;

    const barW = 60.0;
    const barH = 5.0;
    final x = p;
    final y = p + 4;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, barH), const Radius.circular(3)),
      Paint()..color = Colors.black38,
    );
    // Fill
    final fillColor = Color.lerp(
        const Color(0xFF66BB6A), const Color(0xFFEF5350), progress)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW * progress, barH), const Radius.circular(3)),
      Paint()..color = fillColor,
    );

    _drawText(canvas, 'SPEED', Offset(x, y + barH + 2),
        fontSize: 8, color: Colors.white54, bold: false);
  }

  // ── Helper ───────────────────────────────────────────────

  void _drawText(
    Canvas canvas,
    String text,
    Offset origin, {
    required double fontSize,
    required Color color,
    required bool bold,
    bool centerX = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          shadows: bold
              ? [const Shadow(color: Colors.black54, blurRadius: 4)]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = centerX ? origin.dx - tp.width / 2 : origin.dx;
    tp.paint(canvas, Offset(dx, origin.dy));
  }
}
