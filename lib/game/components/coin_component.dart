import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../wave_rider_game.dart';
import 'surfer_component.dart';

class CoinComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<WaveRiderGame> {
  double _bobPhase;
  double _spinAngle = 0.0;
  bool _collected = false;

  CoinComponent({
    required super.position,
    double bobPhaseOffset = 0.0,
  })  : _bobPhase = bobPhaseOffset,
        super(
          size: Vector2(GameConstants.coinR * 2, GameConstants.coinR * 2),
          priority: 2,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: GameConstants.coinR * 0.82));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    _bobPhase += dt * GameConstants.coinBobFreq;
    _spinAngle += dt * 2.8;
    position.x -= gameRef.scrollSpeed * dt;
    position.y +=
        sin(_bobPhase) * GameConstants.coinBobAmp * dt * GameConstants.coinBobFreq;

    if (position.x < -size.x - 20) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (!_collected && other is SurferComponent) {
      _collected = true;
      gameRef.onCoinCollected();
      removeFromParent();
    }
  }

  // ── Rendering ────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawCoin(canvas);
  }

  void _drawCoin(Canvas canvas) {
    final r = GameConstants.coinR;
    final center = Offset(r, r);

    // Glow halo
    canvas.drawCircle(
      center,
      r + 5,
      Paint()
        ..color = GameColors.coinGold.withOpacity(0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Outer ring
    canvas.drawCircle(center, r, Paint()..color = GameColors.coinDark);
    // Main face
    canvas.drawCircle(center, r * 0.88, Paint()..color = GameColors.coinGold);
    // Shine
    canvas.drawCircle(
      Offset(center.dx - r * 0.18, center.dy - r * 0.18),
      r * 0.32,
      Paint()..color = GameColors.coinLight.withOpacity(0.65),
    );

    // Spinning star
    canvas.save();
    canvas.translate(r, r);
    canvas.rotate(_spinAngle);
    canvas.drawPath(
      _starPath(Offset.zero, r * 0.48, r * 0.22, 5),
      Paint()..color = GameColors.coinDark.withOpacity(0.55),
    );
    canvas.restore();
  }

  Path _starPath(Offset center, double outer, double inner, int points) {
    final path = Path();
    final step = pi / points;
    for (int i = 0; i < points * 2; i++) {
      final angle = i * step - pi / 2;
      final r = i.isEven ? outer : inner;
      final pt = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    return path;
  }
}
