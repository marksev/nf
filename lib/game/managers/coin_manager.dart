import 'dart:math';

import 'package:flame/components.dart';

import '../../utils/constants.dart';
import '../wave_rider_game.dart';
import '../components/coin_component.dart';

/// Spawns coin clusters that float above the wave for the player to collect.
class CoinManager extends Component with HasGameRef<WaveRiderGame> {
  double _timer = 0.0;
  double _nextSpawnIn = 3.2;

  @override
  void update(double dt) {
    if (gameRef.gameState != GameState.playing) return;
    _timer += dt;
    if (_timer >= _nextSpawnIn) {
      _timer = 0.0;
      _spawnCluster();
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    _nextSpawnIn = GameConstants.minCoinInterval +
        gameRef.random.nextDouble() *
            (GameConstants.maxCoinInterval - GameConstants.minCoinInterval);
  }

  void _spawnCluster() {
    final waterY = gameRef.getWaterY();
    final startX = gameRef.size.x + 40.0;

    // Coins float 1–2.5 × surfer-height above the wave so they require a jump
    final heightFactor = 1.0 + gameRef.random.nextDouble() * 1.5;
    final baseY = waterY - GameConstants.surferH * heightFactor;

    // 1–5 coins in a horizontal line
    final count = 1 + gameRef.random.nextInt(5);
    for (int i = 0; i < count; i++) {
      gameRef.add(CoinComponent(
        position: Vector2(
          startX + i * (GameConstants.coinR * 3.0),
          baseY,
        ),
        bobPhaseOffset: gameRef.random.nextDouble() * 2 * pi,
      ));
    }
  }
}
