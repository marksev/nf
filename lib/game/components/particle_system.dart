import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Burst of coloured particles spawned on obstacle collision.
class ParticleSystem extends Component {
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  static const List<Color> _palette = [
    Color(0xFFFF6D00), // orange
    Color(0xFFFFD700), // gold
    Color(0xFFFFFFFF), // white
    Color(0xFFE53935), // red
    Color(0xFF42A5F5), // ocean blue
    Color(0xFFB3E5FC), // foam
  ];

  ParticleSystem({required Vector2 spawnPosition}) : super(priority: 15) {
    for (int i = 0; i < 24; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 55.0 + _rng.nextDouble() * 250.0;
      _particles.add(_Particle(
        position: spawnPosition.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        color: _palette[_rng.nextInt(_palette.length)],
        radius: 2.5 + _rng.nextDouble() * 4.5,
        life: 1.0,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final p in _particles) {
      p.life -= dt * 1.75;
      p.position += p.velocity * dt;
      p.velocity *= 0.91; // drag
      p.radius *= 0.985;
    }
    _particles.removeWhere((p) => p.life <= 0);
    if (_particles.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      canvas.drawCircle(
        Offset(p.position.x, p.position.y),
        p.radius.clamp(0.5, 12.0),
        Paint()..color = p.color.withOpacity(p.life.clamp(0.0, 1.0)),
      );
    }
  }
}

class _Particle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double radius;
  double life;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.life,
  });
}
