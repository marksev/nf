import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../wave_rider_game.dart';
import 'surfer_component.dart';

class RockComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<WaveRiderGame> {
  RockComponent({required super.position})
      : super(
          size: Vector2(GameConstants.rockW, GameConstants.rockH),
          priority: 2,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(
      size: Vector2(size.x * 0.62, size.y * 0.58),
      position: Vector2(size.x * 0.19, size.y * 0.06),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= gameRef.scrollSpeed * dt;
    final waterY = gameRef.getWaterY();
    position.y = waterY - size.y * 0.72;
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
    _drawRock(canvas);
  }

  void _drawRock(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // ── Shadow ───────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.50, h * 1.02), width: w * 0.9, height: h * 0.12),
      Paint()..color = Colors.black.withOpacity(0.18),
    );

    // ── Main rock ────────────────────────────────────────
    final rockPath = Path()
      ..moveTo(w * 0.22, h)
      ..lineTo(0, h * 0.65)
      ..lineTo(w * 0.08, h * 0.35)
      ..lineTo(w * 0.25, h * 0.08)
      ..lineTo(w * 0.48, 0)
      ..lineTo(w * 0.72, h * 0.05)
      ..lineTo(w * 0.90, h * 0.28)
      ..lineTo(w, h * 0.55)
      ..lineTo(w * 0.85, h * 0.82)
      ..lineTo(w * 0.78, h)
      ..close();
    canvas.drawPath(rockPath, Paint()..color = GameColors.rockDark);

    // ── Mid-tone face ─────────────────────────────────────
    final midPath = Path()
      ..moveTo(w * 0.28, h * 0.92)
      ..lineTo(w * 0.12, h * 0.62)
      ..lineTo(w * 0.20, h * 0.38)
      ..lineTo(w * 0.38, h * 0.15)
      ..lineTo(w * 0.60, h * 0.10)
      ..lineTo(w * 0.75, h * 0.30)
      ..lineTo(w * 0.82, h * 0.55)
      ..lineTo(w * 0.74, h * 0.82)
      ..lineTo(w * 0.62, h * 0.92)
      ..close();
    canvas.drawPath(midPath, Paint()..color = GameColors.rockMid);

    // ── Light highlight ───────────────────────────────────
    final highPath = Path()
      ..moveTo(w * 0.38, h * 0.18)
      ..lineTo(w * 0.60, h * 0.12)
      ..lineTo(w * 0.66, h * 0.32)
      ..lineTo(w * 0.42, h * 0.40)
      ..close();
    canvas.drawPath(highPath, Paint()..color = GameColors.rockLight);

    // ── Water splash at base ──────────────────────────────
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.50, h), width: w * 1.12, height: h * 0.18),
      pi,
      pi,
      false,
      Paint()
        ..color = GameColors.waveFoam.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }
}
