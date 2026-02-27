import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../wave_rider_game.dart';
import 'surfer_component.dart';

class SharkComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<WaveRiderGame> {
  double _bobPhase;

  SharkComponent({
    required super.position,
    double bobPhaseOffset = 0.0,
  })  : _bobPhase = bobPhaseOffset,
        super(
          size: Vector2(GameConstants.sharkW, GameConstants.sharkH),
          priority: 2,
        );

  @override
  Future<void> onLoad() async {
    // Hitbox on the fin region — the visible danger
    add(RectangleHitbox(
      size: Vector2(size.x * 0.34, size.y * 0.52),
      position: Vector2(size.x * 0.30, 0),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobPhase += dt * 2.5;
    position.x -= gameRef.scrollSpeed * dt;
    final waterY = gameRef.getWaterY();
    position.y = waterY - size.y * 0.44 + sin(_bobPhase) * 3.0;
    if (position.x < -size.x - 20) removeFromParent();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is SurferComponent) {
      gameRef.onObstacleHit();
      removeFromParent();
    }
  }

  // ── Rendering ────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawShark(canvas);
  }

  void _drawShark(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // ── Body ─────────────────────────────────────────────
    final bodyPath = Path()
      ..moveTo(0, h * 0.50)
      ..cubicTo(w * 0.10, h * 0.42, w * 0.35, h * 0.38, w * 0.55, h * 0.40)
      ..cubicTo(w * 0.72, h * 0.42, w * 0.88, h * 0.52, w, h * 0.48)
      ..lineTo(w, h * 0.72)
      ..cubicTo(w * 0.85, h * 0.88, w * 0.65, h * 0.92, w * 0.50, h * 0.88)
      ..cubicTo(w * 0.30, h * 0.92, w * 0.10, h * 0.78, 0, h * 0.70)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = GameColors.sharkGray);

    // Belly
    final bellyPath = Path()
      ..moveTo(w * 0.10, h * 0.56)
      ..cubicTo(w * 0.25, h * 0.49, w * 0.55, h * 0.47, w * 0.84, h * 0.56)
      ..cubicTo(w * 0.72, h * 0.70, w * 0.38, h * 0.74, w * 0.10, h * 0.68)
      ..close();
    canvas.drawPath(bellyPath, Paint()..color = GameColors.sharkLight);

    // ── Dorsal fin ───────────────────────────────────────
    final finPath = Path()
      ..moveTo(w * 0.30, h * 0.43)
      ..lineTo(w * 0.42, h * 0.04)
      ..cubicTo(w * 0.48, 0, w * 0.55, h * 0.06, w * 0.62, h * 0.38)
      ..cubicTo(w * 0.52, h * 0.35, w * 0.40, h * 0.37, w * 0.30, h * 0.43)
      ..close();
    canvas.drawPath(finPath, Paint()..color = GameColors.sharkDark);
    // fin highlight
    canvas.drawLine(
      Offset(w * 0.42, h * 0.04),
      Offset(w * 0.38, h * 0.28),
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 1.5,
    );

    // ── Tail fin ─────────────────────────────────────────
    final tailPath = Path()
      ..moveTo(w * 0.92, h * 0.56)
      ..lineTo(w * 1.02, h * 0.38)
      ..lineTo(w * 1.0, h * 0.60)
      ..lineTo(w * 1.02, h * 0.78)
      ..lineTo(w * 0.92, h * 0.64)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = GameColors.sharkDark);

    // ── Eye ──────────────────────────────────────────────
    canvas.drawCircle(Offset(w * 0.16, h * 0.51), w * 0.040,
        Paint()..color = Colors.black);
    canvas.drawCircle(Offset(w * 0.15, h * 0.50), w * 0.015,
        Paint()..color = Colors.white);

    // ── Teeth ────────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      final tx = w * (0.07 + i * 0.042);
      canvas.drawPath(
        Path()
          ..moveTo(tx, h * 0.565)
          ..lineTo(tx + w * 0.016, h * 0.635)
          ..lineTo(tx + w * 0.032, h * 0.565),
        Paint()..color = Colors.white,
      );
    }
  }
}
