import 'dart:ui';

class GameColors {
  static const Color skyTop = Color(0xFF0A1628);
  static const Color skyBottom = Color(0xFF1565C0);
  static const Color oceanLight = Color(0xFF1976D2);
  static const Color oceanDark = Color(0xFF0D47A1);
  static const Color wave1 = Color(0xFF2196F3);
  static const Color wave2 = Color(0xFF42A5F5);
  static const Color waveFoam = Color(0xFFBBDEFB);
  static const Color surferBoard = Color(0xFFFF6D00);
  static const Color surferBoardStripe = Color(0xFFFFAB40);
  static const Color surferWetsuit = Color(0xFF0D47A1);
  static const Color surferSkin = Color(0xFFFFB74D);
  static const Color surferHair = Color(0xFF4E342E);
  static const Color sharkGray = Color(0xFF607D8B);
  static const Color sharkLight = Color(0xFF78909C);
  static const Color sharkDark = Color(0xFF455A64);
  static const Color rockDark = Color(0xFF4A2F1A);
  static const Color rockMid = Color(0xFF6D4C41);
  static const Color rockLight = Color(0xFF8D6E63);
  static const Color coinGold = Color(0xFFFFD700);
  static const Color coinLight = Color(0xFFFFF176);
  static const Color coinDark = Color(0xFFF9A825);
  static const Color heartRed = Color(0xFFE53935);
  static const Color heartEmpty = Color(0xFF546E7A);
  static const Color hudBg = Color(0xAA000000);
  static const Color hudText = Color(0xFFFFFFFF);
  static const Color scoreGold = Color(0xFFFFD700);
  static const Color gameOverBg = Color(0xCC001A3A);
}

class GameConstants {
  // Physics
  static const double gravity = 1100.0;
  static const double jumpVelocity = 600.0;
  static const double waveAmplitude = 14.0;
  static const double waveFrequency = 1.3;

  // Speed
  static const double initialSpeed = 210.0;
  static const double maxSpeed = 540.0;
  static const double speedIncreaseRate = 6.5;

  // Scoring
  static const int scorePerSecond = 12;
  static const int coinScore = 25;

  // Lives & Invincibility
  static const int maxLives = 3;
  static const double invincibilityTime = 2.5;

  // Player
  static const double surferW = 68.0;
  static const double surferH = 56.0;
  static const double playerXRatio = 0.18;

  // Obstacles
  static const double sharkW = 80.0;
  static const double sharkH = 58.0;
  static const double rockW = 52.0;
  static const double rockH = 72.0;
  static const double minObstacleInterval = 1.4;
  static const double maxObstacleInterval = 3.0;

  // Coins
  static const double coinR = 16.0;
  static const double coinBobAmp = 6.0;
  static const double coinBobFreq = 2.5;
  static const double minCoinInterval = 1.8;
  static const double maxCoinInterval = 3.5;

  // Water level ratio (from top of screen)
  static const double waterRatio = 0.62;

  // HUD
  static const double hudPadding = 14.0;
  static const double hudFontSize = 20.0;
  static const double heartSize = 22.0;
}
