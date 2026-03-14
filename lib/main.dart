import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:blocky_blast/ads/banner_ad_widget.dart';
import 'dart:math';

// ─── CONSTANTS ───────────────────────────────────────────────────────────────
const int kGridSize = 8;
const Color kBgColor = Color(0xFF1a0a2e);
const Color kPanelColor = Color(0xFF2d1457);
const Color kGridBgColor = Color(0xFF0f0720);
const Color kCellEmptyColor = Color(0xFF1e0d3a);
const Color kCellBorderColor = Color(0xFF2a1250);
const Color kGoldColor = Color(0xFFFFD700);
const Color kAccentColor = Color(0xFFff6b9d);
const Color kAccent2Color = Color(0xFFc44dff);
const Color kTextColor = Color(0xFFf0e6ff);

/// How many grid-cell heights the drag ghost is lifted above the finger.
const double kDragOffsetCells = 1.8;

// ─── PIECE COLORS ─────────────────────────────────────────────────────────────
class PieceColor {
  final Color fill, shine, shadow;
  const PieceColor(this.fill, this.shine, this.shadow);
}

const List<PieceColor> kPieceColors = [
  PieceColor(Color(0xFFFF6B6B), Color(0xFFFF9999), Color(0xFFCC3333)), // red
  PieceColor(Color(0xFFFFD166), Color(0xFFFFE99A), Color(0xFFCC9900)), // yellow
  PieceColor(Color(0xFF06D6A0), Color(0xFF6EFFD0), Color(0xFF049970)), // green
  PieceColor(Color(0xFF118AB2), Color(0xFF56C8F0), Color(0xFF0A5F7A)), // blue
  PieceColor(Color(0xFFC44DFF), Color(0xFFE090FF), Color(0xFF8800CC)), // purple
  PieceColor(Color(0xFFFF9F43), Color(0xFFFFCA85), Color(0xFFCC6600)), // orange
  PieceColor(Color(0xFFFF6B9D), Color(0xFFFFAACB), Color(0xFFCC3366)), // pink
  PieceColor(Color(0xFF48DBFB), Color(0xFF99EEFF), Color(0xFF009FCC)), // cyan
];

// ─── SHAPES ──────────────────────────────────────────────────────────────────
const List<List<List<int>>> kShapes = [
  [[0,0]],
  [[0,0],[0,1]],
  [[0,0],[1,0]],
  [[0,0],[0,1],[0,2]],
  [[0,0],[1,0],[2,0]],
  [[0,0],[0,1],[1,0]],
  [[0,0],[0,1],[1,1]],
  [[0,0],[1,0],[1,1]],
  [[1,0],[1,1],[0,1]],
  [[0,0],[1,0],[2,0],[2,1]],
  [[0,0],[0,1],[0,2],[1,0]],
  [[0,0],[1,0],[2,0],[0,1]],
  [[0,0],[0,1],[0,2],[1,2]],
  [[0,1],[1,1],[2,1],[2,0]],
  [[1,0],[1,1],[1,2],[0,2]],
  [[0,0],[0,1],[1,0],[2,0]],
  [[0,0],[0,1],[0,2],[1,0]],
  [[0,1],[1,0],[1,1],[1,2]],
  [[0,0],[1,0],[1,1],[2,0]],
  [[1,0],[1,1],[1,2],[0,1]],
  [[0,0],[0,1],[1,0],[1,1]],
  [[0,1],[0,2],[1,0],[1,1]],
  [[0,0],[0,1],[1,1],[1,2]],
  [[0,0],[0,1],[0,2],[0,3],[0,4]],
  [[0,0],[1,0],[2,0],[3,0],[4,0]],
  [[0,0],[0,1],[0,2],[0,3]],
  [[0,0],[1,0],[2,0],[3,0]],
  [[0,0],[0,1],[1,0],[1,1]],

  [[0,0],[0,1],[1,0],[1,1],[2,0],[2,1]],
  [[0,0],[0,1],[0,2],[1,0],[1,1],[1,2]],
];

// ─── MODELS ──────────────────────────────────────────────────────────────────
class Piece {
  final List<List<int>> shape;
  final int colorIdx;
  const Piece(this.shape, this.colorIdx);

  int get maxRow => shape.map((e) => e[0]).reduce(max);
  int get maxCol => shape.map((e) => e[1]).reduce(max);
  int get rows => maxRow + 1;
  int get cols => maxCol + 1;
}

class Particle {
  double x, y, vx, vy, r, life, decay;
  final Color color;
  Particle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.r, required this.life,
    required this.decay, required this.color,
  });
}

// ─── AUDIO ───────────────────────────────────────────────────────────────────

class SoundManager {
  void playPickup() => AudioPlayer().play(AssetSource('sounds/pickup.mp3'));
  void playPlace()  => AudioPlayer().play(AssetSource('sounds/place.mp3'));
  void playClear()  => AudioPlayer().play(AssetSource('sounds/clear.mp3'));
  void playDenied() => AudioPlayer().play(AssetSource('sounds/denied.mp3'));
  void dispose() {}
  Future<void> init() async {}
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BlockyBlastApp());
}

class BlockyBlastApp extends StatelessWidget {
  const BlockyBlastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brick Pop',
      theme: ThemeData.dark(),
      home: const GamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── GAME PAGE ────────────────────────────────────────────────────────────────
class GamePage extends StatefulWidget {
  const GamePage({super.key});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  final _gridKey = GlobalKey();
  final _slotKeys = List.generate(3, (_) => GlobalKey());

  late List<List<int>> _board;
  late List<Piece?> _pieces;
  int _score = 0;
  int _best = 0;
  bool _gameOver = false;
  bool _continueAvailable = false;
  RewardedAd? _rewardedAd;

  // Drag state
  int? _dragSlotIdx;
  Offset? _dragPos;
  int? _previewR, _previewC;
  bool _validDrop = false;

  // Clearing animation
  Set<String> _clearingCells = {};
  bool _isClearing = false;

  // Particles
  final List<Particle> _particles = [];
  late Ticker _ticker;

  final _rand = Random();
  final _sounds = SoundManager();

  @override
  void initState() {
    super.initState();
    _board = _emptyBoard();
    _pieces = [null, null, null];
    _ticker = createTicker(_onTick)..start();
    _loadBest();
    _loadRewardedAd();
    _refillTray();
    _sounds.init();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sounds.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    if (_particles.isNotEmpty) {
      setState(() {
        _particles.removeWhere((p) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.25;
          p.life -= p.decay;
          return p.life <= 0;
        });
      });
    }
  }

  List<List<int>> _emptyBoard() =>
      List.generate(kGridSize, (_) => List.filled(kGridSize, 0));

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _best = prefs.getInt('bb_best') ?? 0;
      _continueAvailable = !(prefs.getBool('bb_continue_used') ?? false);
    });
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bb_best', _best);
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => setState(() => _rewardedAd = ad),
        onAdFailedToLoad: (_) => setState(() => _rewardedAd = null),
      ),
    );
  }

  void _continueGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bb_continue_used', true);
    setState(() {
      _continueAvailable = false;
      _gameOver = false;
      _refillTray();
    });
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      _continueGame();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _continueGame();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (_, __) => _continueGame());
    _rewardedAd = null;
  }

  Piece _randomPiece() {
    final shape = kShapes[_rand.nextInt(kShapes.length)];
    return Piece(shape, _rand.nextInt(kPieceColors.length));
  }

  void _refillTray() {
    for (int i = 0; i < 3; i++) {
      if (_pieces[i] == null) _pieces[i] = _randomPiece();
    }
  }

  bool _canPlace(Piece piece, int startR, int startC) {
    for (final cell in piece.shape) {
      final r = startR + cell[0];
      final c = startC + cell[1];
      if (r < 0 || r >= kGridSize || c < 0 || c >= kGridSize) return false;
      if (_board[r][c] != 0) return false;
    }
    return true;
  }

  void _placePiece(int slotIdx, int startR, int startC) {
    if (_isClearing) return;
    final piece = _pieces[slotIdx]!;
    final colorVal = piece.colorIdx + 1;
    for (final cell in piece.shape) {
      _board[startR + cell[0]][startC + cell[1]] = colorVal;
    }

    // Haptic + sound for successful placement
    HapticFeedback.heavyImpact();
    _sounds.playPlace();

    setState(() {
      _pieces[slotIdx] = null;
      _score += piece.shape.length;
      if (_score > _best) {
        _best = _score;
        _saveBest();
      }
    });

    _clearLines();

    if (_pieces.every((p) => p == null)) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _refillTray());
      });
    }

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _checkGameOver();
    });
  }

  void _clearLines() {
    final fullRows = <int>[];
    final fullCols = <int>[];

    for (int r = 0; r < kGridSize; r++) {
      if (_board[r].every((v) => v != 0)) fullRows.add(r);
    }
    for (int c = 0; c < kGridSize; c++) {
      if (List.generate(kGridSize, (r) => _board[r][c]).every((v) => v != 0)) {
        fullCols.add(c);
      }
    }

    if (fullRows.isEmpty && fullCols.isEmpty) return;

    // Haptic + sound for line clear (triggered immediately when lines detected)
    HapticFeedback.lightImpact();
    _sounds.playClear();

    final clearing = <String>{};
    for (final r in fullRows) {
      for (int c = 0; c < kGridSize; c++) clearing.add('$r,$c');
    }
    for (final c in fullCols) {
      for (int r = 0; r < kGridSize; r++) clearing.add('$r,$c');
    }

    final pts = clearing.length;

    setState(() {
      _clearingCells = clearing;
      _isClearing = true;
    });

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      final gridPos = gridBox?.localToGlobal(Offset.zero);
      final cellW = gridBox != null ? gridBox.size.width / kGridSize : 40.0;
      final cellH = gridBox != null ? gridBox.size.height / kGridSize : 40.0;

      setState(() {
        for (final key in clearing) {
          final parts = key.split(',');
          _board[int.parse(parts[0])][int.parse(parts[1])] = 0;
        }
        _clearingCells = {};
        _isClearing = false;
        _score += pts;
        if (_score > _best) {
          _best = _score;
          _saveBest();
        }
      });

      if (gridPos != null) {
        for (final key in clearing) {
          final parts = key.split(',');
          final r = int.parse(parts[0]);
          final c = int.parse(parts[1]);
          _spawnParticles(
            gridPos.dx + c * cellW + cellW / 2,
            gridPos.dy + r * cellH + cellH / 2,
            3,
          );
        }
      }
    });
  }

  void _spawnParticles(double x, double y, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _rand.nextDouble() * pi * 2;
      final speed = 2 + _rand.nextDouble() * 5;
      _particles.add(Particle(
        x: x, y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 2,
        r: 3 + _rand.nextDouble() * 5,
        life: 1.0,
        decay: 0.03 + _rand.nextDouble() * 0.04,
        color: kPieceColors[_rand.nextInt(kPieceColors.length)].fill,
      ));
    }
  }

  void _checkGameOver() {
    final remaining = _pieces.where((p) => p != null).toList();
    if (remaining.isEmpty) return;
    for (final piece in remaining) {
      for (int r = 0; r < kGridSize; r++) {
        for (int c = 0; c < kGridSize; c++) {
          if (_canPlace(piece!, r, c)) return;
        }
      }
    }
    setState(() => _gameOver = true);
  }

  void _restartGame() async {
    if (_continueAvailable) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bb_continue_used', true);
      _continueAvailable = false;
    }
    setState(() {
      _gameOver = false;
      _score = 0;
      _board = _emptyBoard();
      _pieces = [null, null, null];
      _clearingCells = {};
      _isClearing = false;
      _particles.clear();
      _refillTray();
    });
  }

  // ─── DRAG ─────────────────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails details) {
    if (_isClearing) return;
    for (int i = 0; i < 3; i++) {
      if (_pieces[i] == null) continue;
      final box = _slotKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final local = box.globalToLocal(details.globalPosition);
      if (local.dx >= 0 && local.dy >= 0 &&
          local.dx <= box.size.width && local.dy <= box.size.height) {
        // Haptic + sound for piece pickup
        HapticFeedback.mediumImpact();
        _sounds.playPickup();
        setState(() {
          _dragSlotIdx = i;
          _dragPos = details.globalPosition;
        });
        return;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragSlotIdx == null) return;
    setState(() {
      _dragPos = details.globalPosition;
      _updatePreview(details.globalPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragSlotIdx == null) return;
    final slotIdx = _dragSlotIdx!;
    final pr = _previewR;
    final pc = _previewC;
    final valid = _validDrop;
    final pos = _dragPos; // capture before setState clears it

    setState(() {
      _dragSlotIdx = null;
      _dragPos = null;
      _previewR = null;
      _previewC = null;
      _validDrop = false;
    });

    if (valid && pr != null && pc != null) {
      _placePiece(slotIdx, pr, pc);
    } else {
      _sounds.playDenied();
      HapticFeedback.mediumImpact();
      // Extra feedback when released completely outside the grid
      if (pos != null) {
        final gridBox =
            _gridKey.currentContext?.findRenderObject() as RenderBox?;
        if (gridBox != null) {
          final local = gridBox.globalToLocal(pos);
          final outside = local.dx < 0 ||
              local.dy < 0 ||
              local.dx > gridBox.size.width ||
              local.dy > gridBox.size.height;
          if (outside) HapticFeedback.mediumImpact();
        }
      }
    }
  }

  /// Computes the grid preview position for a drag, taking the upward ghost
  /// offset into account so the preview matches what the player sees.
  void _updatePreview(Offset globalPos) {
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null || _dragSlotIdx == null) {
      _previewR = null;
      _previewC = null;
      _validDrop = false;
      return;
    }
    final cellW = gridBox.size.width / kGridSize;
    final cellH = gridBox.size.height / kGridSize;
    final piece = _pieces[_dragSlotIdx!]!;

    // Adjust for the upward ghost offset so the preview matches the ghost.
    final adjustedPos = Offset(globalPos.dx, globalPos.dy - cellH * kDragOffsetCells);
    final localPos = gridBox.globalToLocal(adjustedPos);

    final col = (localPos.dx / cellW - piece.cols / 2).round();
    final row = (localPos.dy / cellH - piece.rows / 2).round();

    if (_canPlace(piece, row, col)) {
      _previewR = row;
      _previewC = col;
      _validDrop = true;
    } else {
      _previewR = null;
      _previewC = null;
      _validDrop = false;
    }
  }

  double get _ghostCellSize {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    return box != null ? box.size.width / kGridSize : 40.0;
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildGrid(),
                        ),
                      ),
                    ),
                  ),
                  _buildTray(),
                  const Center(child: BannerAdWidget()),
                ],
              ),
            ),
            // Drag ghost — rendered above all other content
            if (_dragSlotIdx != null && _dragPos != null) _buildDragGhost(),
            // Particles
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ParticlePainter(_particles),
                ),
              ),
            ),
            // Game Over
            if (_gameOver) _buildGameOver(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [kAccentColor, kAccent2Color, Color(0xFF6bcbff)],
            ).createShader(bounds),
            child: const Text(
              'Brick Pop',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const Spacer(),
          _scoreBox('SCORE', _score),
          const SizedBox(width: 8),
          _scoreBox('BEST', _best),
        ],
      ),
    );
  }

  Widget _scoreBox(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: kPanelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccent2Color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF9b7fc4), letterSpacing: 1.5)),
          Text(
            value.toString(),
            style: const TextStyle(
                fontSize: 24, color: kGoldColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        color: kGridBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccent2Color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 32,
              offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: CustomPaint(
        key: _gridKey,
        painter: GridPainter(
          board: _board,
          clearingCells: _clearingCells,
          previewRow: _previewR,
          previewCol: _previewC,
          previewPiece: _dragSlotIdx != null ? _pieces[_dragSlotIdx!] : null,
        ),
        child: const AspectRatio(aspectRatio: 1),
      ),
    );
  }

  Widget _buildTray() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  key: _slotKeys[i],
                  decoration: BoxDecoration(
                    color: kPanelColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: kAccent2Color.withOpacity(0.2), width: 2),
                  ),
                  child: _pieces[i] == null
                      ? null
                      : Opacity(
                          opacity: _dragSlotIdx == i ? 0.35 : 1.0,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: SizedBox(
                                  width: _pieces[i]!.cols * 20.0 + 8,
                                  height: _pieces[i]!.rows * 20.0 + 8,
                                  child: CustomPaint(
                                    painter: PiecePainter(
                                        piece: _pieces[i]!, cellSize: 18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Builds the floating ghost piece shown while dragging.
  /// The ghost is offset upward by [kDragOffsetCells] grid-cell heights so
  /// the piece is always visible above the player's finger/cursor.
  Widget _buildDragGhost() {
    final piece = _pieces[_dragSlotIdx!]!;
    final cs = _ghostCellSize;
    final ghostW = piece.cols * cs + 8;
    final ghostH = piece.rows * cs + 8;
    // Lift the ghost upward so the finger doesn't obscure it.
    final yOffset = cs * kDragOffsetCells;
    return Positioned(
      left: _dragPos!.dx - ghostW / 2,
      top: _dragPos!.dy - ghostH / 2 - yOffset,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(
            width: ghostW,
            height: ghostH,
            child: CustomPaint(
              painter: PiecePainter(piece: piece, cellSize: cs - 3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    return Container(
      color: const Color(0xD9000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [kAccentColor, kAccent2Color],
              ).createShader(bounds),
              child: const Text(
                'Game Over',
                style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $_score',
              style: const TextStyle(
                  fontSize: 26,
                  color: kGoldColor,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text('Play Again',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            if (_continueAvailable) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showRewardedAd,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch Ad to Continue',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGoldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── PAINTERS ─────────────────────────────────────────────────────────────────

class GridPainter extends CustomPainter {
  final List<List<int>> board;
  final Set<String> clearingCells;
  final int? previewRow, previewCol;
  final Piece? previewPiece;

  GridPainter({
    required this.board,
    required this.clearingCells,
    this.previewRow,
    this.previewCol,
    this.previewPiece,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / kGridSize;
    final cellH = size.height / kGridSize;
    const gap = 3.0;
    const radius = Radius.circular(5);

    // Collect preview positions
    final previewSet = <String>{};
    if (previewPiece != null && previewRow != null && previewCol != null) {
      for (final cell in previewPiece!.shape) {
        final r = previewRow! + cell[0];
        final c = previewCol! + cell[1];
        if (r >= 0 && r < kGridSize && c >= 0 && c < kGridSize) {
          previewSet.add('$r,$c');
        }
      }
    }

    for (int r = 0; r < kGridSize; r++) {
      for (int c = 0; c < kGridSize; c++) {
        final x = c * cellW + gap / 2;
        final y = r * cellH + gap / 2;
        final w = cellW - gap;
        final h = cellH - gap;
        final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h), radius);
        final key = '$r,$c';
        final val = board[r][c];
        final isClearing = clearingCells.contains(key);
        final isPreview = previewSet.contains(key) && val == 0;

        if (isClearing) {
          // Flash white during clearing animation
          canvas.drawRRect(rect, Paint()..color = Colors.white.withOpacity(0.9));
        } else if (val != 0) {
          final pc = kPieceColors[(val - 1) % kPieceColors.length];
          final grad = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [pc.shine, pc.fill],
          ).createShader(Rect.fromLTWH(x, y, w, h));
          canvas.drawRRect(rect, Paint()..shader = grad);
          // Shine highlight
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x + 3, y + 3, w - 6, (h - 6) * 0.4),
                const Radius.circular(3)),
            Paint()..color = Colors.white.withOpacity(0.25),
          );
        } else if (isPreview) {
          final pc = kPieceColors[previewPiece!.colorIdx];
          canvas.drawRRect(
              rect, Paint()..color = pc.fill.withOpacity(0.6));
          canvas.drawRRect(
              rect,
              Paint()
                ..color = pc.fill.withOpacity(0.8)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5);
        } else {
          canvas.drawRRect(rect, Paint()..color = kCellEmptyColor);
          canvas.drawRRect(
              rect,
              Paint()
                ..color = kCellBorderColor
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
        }
      }
    }
  }

  @override
  bool shouldRepaint(GridPainter old) => true;
}

class PiecePainter extends CustomPainter {
  final Piece piece;
  final double cellSize;

  PiecePainter({required this.piece, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final pc = kPieceColors[piece.colorIdx];
    const pad = 4.0;
    const radius = Radius.circular(5);

    for (final cell in piece.shape) {
      final x = pad + cell[1] * cellSize;
      final y = pad + cell[0] * cellSize;
      final sz = cellSize - 2;

      // Shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + 2, y + 2, sz, sz), radius),
        Paint()..color = pc.shadow,
      );
      // Main gradient
      final grad = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [pc.shine, pc.fill],
      ).createShader(Rect.fromLTWH(x, y, sz, sz));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, sz, sz), radius),
        Paint()..shader = grad,
      );
      // Shine
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 3, y + 3, sz - 6, (sz - 6) * 0.4),
            const Radius.circular(3)),
        Paint()..color = Colors.white.withOpacity(0.25),
      );
    }
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.piece != piece || old.cellSize != cellSize;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.r,
        Paint()..color = p.color.withOpacity(p.life.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => true;
}
