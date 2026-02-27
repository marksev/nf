import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/wave_rider_game.dart';
import '../utils/constants.dart';

/// Flutter widget that hosts the Flame game and stacks the game-over overlay
/// on top when the game ends. Recreating [WaveRiderGame] on each restart keeps
/// the game logic clean — no manual state-reset needed.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late WaveRiderGame _game;
  UniqueKey _gameKey = UniqueKey();
  bool _showGameOver = false;

  @override
  void initState() {
    super.initState();
    _createGame();
  }

  void _createGame() {
    _game = WaveRiderGame();
    _game.onGameOver = () {
      if (mounted) setState(() => _showGameOver = true);
    };
  }

  void _restart() {
    setState(() {
      _showGameOver = false;
      _gameKey = UniqueKey(); // forces GameWidget to rebuild
      _createGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(key: _gameKey, game: _game),
          if (_showGameOver)
            _GameOverOverlay(
              game: _game,
              onRestart: _restart,
              onMainMenu: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

// ── Game-Over Overlay ─────────────────────────────────────────────────────────

class _GameOverOverlay extends StatefulWidget {
  final WaveRiderGame game;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const _GameOverOverlay({
    required this.game,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.game.score;
    final best = widget.game.highScore;
    final newRecord = widget.game.isNewHighScore;

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: GameColors.gameOverBg,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2137), Color(0xFF0A3A5C)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF42A5F5).withOpacity(0.45),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  const Text(
                    'WIPED OUT!',
                    style: TextStyle(
                      color: Color(0xFF42A5F5),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // New record badge
                  if (newRecord)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: GameColors.coinGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: GameColors.coinGold, width: 1.5),
                      ),
                      child: const Text(
                        'NEW RECORD',
                        style: TextStyle(
                          color: GameColors.coinGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                  // Score rows
                  _ScoreRow(label: 'SCORE', value: score, color: Colors.white),
                  const SizedBox(height: 6),
                  _ScoreRow(
                      label: 'BEST',
                      value: best,
                      color: GameColors.coinGold),

                  const SizedBox(height: 26),

                  // Buttons
                  _OverlayButton(
                    label: 'PLAY AGAIN',
                    color: const Color(0xFF00BCD4),
                    onTap: widget.onRestart,
                  ),
                  const SizedBox(height: 11),
                  _OverlayButton(
                    label: 'MAIN MENU',
                    color: const Color(0xFF546E7A),
                    onTap: widget.onMainMenu,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ScoreRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 13, letterSpacing: 2)),
        Text('$value',
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.38),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
