import 'package:shared_preferences/shared_preferences.dart';

class HighScoreManager {
  static const String _key = 'wave_rider_high_score';

  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  /// Returns true if [score] is a new high score and it was saved.
  static Future<bool> saveIfHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    if (score > current) {
      await prefs.setInt(_key, score);
      return true;
    }
    return false;
  }
}
