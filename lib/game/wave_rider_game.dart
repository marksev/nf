import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/hud_component.dart';
import 'components/particle_system.dart';
import 'components/surfer_component.dart';
import 'components/wave_background.dart';
import 'managers/coin_manager.dart';
import 'managers/obstacle_manager.dart';
import '../utils/constants.dart';
import '../utils/high_score_manager.dart';

enum GameState { playing, gameOver }

class WaveRiderGame extends FlameGame with TapCallbacks, HasCollisionDetection {
  // ── State ────────────────────────────────────────────────
  GameState gameState = GameState.playing;
  int score = 0;
  int lives = GameConstants.maxLives;
  double scrollSpeed = GameConstants.initialSpeed;
  double elapsedTime = 0.0;
  double wavePhase = 0.0;
  int highScore = 0;
  bool isNewHighScore = false;

  // ── Components ───────────────────────────────────────────
  late SurferComponent surfer;
  final Random random = Random();

  /// Called by [GameScreen] when the game ends so it can show the overlay.
  VoidCallback? onGameOver;

  // ── Flame overrides ──────────────────────────────────────
  @override
  Color backgroundColor() => GameColors.skyTop;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    highScore = await HighScoreManager.getHighScore();
    _buildScene();
  }

  void _buildScene() {
    add(WaveBackground());
    add(ObstacleManager());
    add(CoinManager());

    final px = size.x * GameConstants.playerXRatio;
    final waterY = size.y * GameConstants.waterRatio;
    surfer = SurferComponent(
      position: Vector2(px, waterY - GameConstants.surferH),
    );
    add(surfer);

    add(HudComponent());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameState != GameState.playing) return;

    elapsedTime += dt;
    wavePhase += dt * GameConstants.waveFrequency;

    scrollSpeed = (GameConstants.initialSpeed +
            GameConstants.speedIncreaseRate * elapsedTime)
        .clamp(GameConstants.initialSpeed, GameConstants.maxSpeed);

    score += (dt * GameConstants.scorePerSecond).round();
    if (score > highScore) highScore = score;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.playing) surfer.jump();
  }

  // ── Helpers used by components ───────────────────────────

  /// Y coordinate of the wave surface in screen space.
  double getWaterY() {
    return size.y * GameConstants.waterRatio +
        sin(wavePhase) * GameConstants.waveAmplitude;
  }

  // ── Game events ──────────────────────────────────────────

  void onCoinCollected() {
    score += GameConstants.coinScore;
    AudioHelper.playCollect();
  }

  void onObstacleHit() {
    if (surfer.isInvincible) return;
    lives--;
    surfer.triggerInvincibility();
    add(ParticleSystem(spawnPosition: surfer.center));
    AudioHelper.playCollision();
    if (lives <= 0) {
      lives = 0;
      _triggerGameOver();
    }
  }

  void _triggerGameOver() async {
    gameState = GameState.gameOver;
    isNewHighScore = await HighScoreManager.saveIfHighScore(score);
    highScore = await HighScoreManager.getHighScore();
    onGameOver?.call();
  }
}

// ---------------------------------------------------------------------------
// Stub audio helper.
// To enable sound: add .mp3 files to assets/audio/, declare them in
// pubspec.yaml, then replace each method body with a FlameAudio.play() call.
// ---------------------------------------------------------------------------
class AudioHelper {
  static void playJump() {
    // FlameAudio.play('jump.mp3');
  }

  static void playCollision() {
    // FlameAudio.play('collision.mp3');
  }

  static void playCollect() {
    // FlameAudio.play('collect.mp3');
  }

  static void playBgMusic() {
    // FlameAudio.bgm.play('background_music.mp3');
  }

  static void stopBgMusic() {
    // FlameAudio.bgm.stop();
  }
}
