import 'dart:math';

import 'package:flame/components.dart';

import '../../utils/constants.dart';
import '../wave_rider_game.dart';
import '../components/shark_component.dart';
import '../components/rock_component.dart';

/// Spawns sharks and rocks at randomised intervals that shorten as the game
/// progresses, keeping difficulty scaling smooth.
class ObstacleManager extends Component with HasGameRef<WaveRiderGame> {
  double _timer = 0.0;
  double _nextSpawnIn = 2.8; // delay before the very first obstacle

  @override
  void update(double dt) {
    if (gameRef.gameState != GameState.playing) return;
    _timer += dt;
    if (_timer >= _nextSpawnIn) {
      _timer = 0.0;
      _spawnObstacle();
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    // Lerp spawn interval from max → min over the first 60 s of gameplay
    final progress = (gameRef.elapsedTime / 60.0).clamp(0.0, 1.0);
    final base = _lerp(GameConstants.maxObstacleInterval,
        GameConstants.minObstacleInterval, progress);
    // Add ±50 % random jitter so obstacles don't feel mechanical
    _nextSpawnIn = base * (0.70 + gameRef.random.nextDouble() * 0.60);
  }

  void _spawnObstacle() {
    final x = gameRef.size.x + 60.0;
    final waterY = gameRef.getWaterY();

    if (gameRef.random.nextDouble() < 0.55) {
      // Shark (55 % chance)
      gameRef.add(SharkComponent(
        position: Vector2(x, waterY - GameConstants.sharkH * 0.44),
        bobPhaseOffset: gameRef.random.nextDouble() * 2 * pi,
      ));
    } else {
      // Rock (45 % chance)
      gameRef.add(RockComponent(
        position: Vector2(x, waterY - GameConstants.rockH * 0.72),
      ));
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
