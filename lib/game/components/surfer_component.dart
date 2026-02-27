import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../wave_rider_game.dart';

class SurferComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<WaveRiderGame> {
  // ── Physics ──────────────────────────────────────────────
  double _velocityY = 0.0;
  bool _isJumping = false;

  // ── Invincibility ────────────────────────────────────────
  bool isInvincible = false;
  double _invincibilityTimer = 0.0;
  double _blinkTimer = 0.0;
  bool _visible = true;

  // ── Animation ────────────────────────────────────────────
  double _legPhase = 0.0;

  SurferComponent({required super.position})
      : super(
          size: Vector2(GameConstants.surferW, GameConstants.surferH),
          priority: 3,
        );

  /// Centre point in world space — used as particle spawn origin.
  Vector2 get center =>
      Vector2(position.x + size.x / 2, position.y + size.y / 2);

  @override
  Future<void> onLoad() async {
    // Hitbox is intentionally smaller than the visual for fair gameplay.
    add(RectangleHitbox(
      size: Vector2(size.x * 0.52, size.y * 0.62),
      position: Vector2(size.x * 0.24, size.y * 0.12),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _legPhase += dt * 4.0;

    final groundY = gameRef.getWaterY() - size.y;

    // Blinking during invincibility
    if (isInvincible) {
      _invincibilityTimer -= dt;
      _blinkTimer += dt;
      _visible = (_blinkTimer * 8).floor().isEven;
      if (_invincibilityTimer <= 0) {
        isInvincible = false;
        _visible = true;
      }
    }

    // Physics
    if (_isJumping) {
      _velocityY += GameConstants.gravity * dt;
      position.y += _velocityY * dt;
      if (position.y >= groundY) {
        position.y = groundY;
        _velocityY = 0.0;
        _isJumping = false;
      }
    } else {
      // Surf on the wave surface
      position.y = groundY;
    }

    position.y = position.y.clamp(0.0, groundY);
  }

  void jump() {
    if (!_isJumping) {
      _isJumping = true;
      _velocityY = -GameConstants.jumpVelocity;
      AudioHelper.playJump();
    }
  }

  void triggerInvincibility() {
    isInvincible = true;
    _invincibilityTimer = GameConstants.invincibilityTime;
    _blinkTimer = 0.0;
    _visible = true;
  }

  // ── Rendering ────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    super.render(canvas);
    _drawSurfer(canvas);
  }

  void _drawSurfer(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final legSway = sin(_legPhase) * 2.0;
    final skinPaint = Paint()..color = GameColors.surferSkin;

    // ── Surfboard ────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      ),
      Paint()..color = GameColors.surferBoard,
    );
    // board highlight stripe
    canvas.drawRect(
      Rect.fromLTWH(w * 0.28, h * 0.83, w * 0.36, h * 0.06),
      Paint()..color = GameColors.surferBoardStripe,
    );
    // board shine
    canvas.drawRect(
      Rect.fromLTWH(w * 0.06, h * 0.86, w * 0.14, h * 0.04),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

    // ── Legs ─────────────────────────────────────────────
    // back leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.63 + legSway, w * 0.15, h * 0.2),
        const Radius.circular(3),
      ),
      skinPaint,
    );
    // front leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.44, h * 0.61 - legSway, w * 0.15, h * 0.22),
        const Radius.circular(3),
      ),
      skinPaint,
    );

    // ── Wetsuit torso ────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.36, w * 0.44, h * 0.3),
        const Radius.circular(5),
      ),
      Paint()..color = GameColors.surferWetsuit,
    );
    // accent stripe on wetsuit
    canvas.drawRect(
      Rect.fromLTWH(w * 0.38, h * 0.38, w * 0.06, h * 0.26),
      Paint()..color = GameColors.surferBoardStripe.withOpacity(0.7),
    );

    // ── Back arm ─────────────────────────────────────────
    canvas.drawLine(
      Offset(w * 0.24, h * 0.44),
      Offset(w * 0.04, h * 0.37),
      Paint()
        ..color = GameColors.surferSkin
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // ── Front arm (extended forward/right) ───────────────
    canvas.drawLine(
      Offset(w * 0.66, h * 0.43),
      Offset(w * 0.96, h * 0.33),
      Paint()
        ..color = GameColors.surferSkin
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // ── Head ─────────────────────────────────────────────
    canvas.drawCircle(Offset(w * 0.70, h * 0.25), w * 0.19, skinPaint);
    // hair
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.70, h * 0.25), radius: w * 0.19),
      pi,
      pi,
      false,
      Paint()
        ..color = GameColors.surferHair
        ..style = PaintingStyle.fill,
    );
    // eye
    canvas.drawCircle(
      Offset(w * 0.79, h * 0.21),
      w * 0.026,
      Paint()..color = Colors.black,
    );
    // smile
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.77, h * 0.29), width: w * 0.10, height: w * 0.07),
      0,
      pi,
      false,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
