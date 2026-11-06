import 'package:flutter/foundation.dart';
import 'audio_service.dart';

// ---------- Kelime yardımcıları ----------

/// Karşılaştırma için kelimeyi sadeleştirir: küçük harf, aksan/diakritik yok,
/// noktalama ve boşluk yok. TR'deki i/ı/İ/I hepsi aynı sayılır.
String normalizeWord(String input) {
  const map = {
    'İ': 'i', 'I': 'i', 'ı': 'i',
    'ä': 'a', 'Ä': 'a', 'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
    'ö': 'o', 'Ö': 'o', 'ò': 'o', 'ó': 'o', 'ô': 'o',
    'ü': 'u', 'Ü': 'u', 'ù': 'u', 'ú': 'u', 'û': 'u',
    'ß': 'ss', 'ş': 's', 'Ş': 's', 'ç': 'c', 'Ç': 'c', 'ğ': 'g', 'Ğ': 'g',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'í': 'i', 'ì': 'i', 'î': 'i',
    'ñ': 'n',
    // Arapça
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و',
    'ئ': 'ي',
  };
  final b = StringBuffer();
  for (final ch in input.split('')) {
    final code = ch.codeUnitAt(0);
    if (code >= 0x064B && code <= 0x065F) continue; // Arapça harekeler
    if (code == 0x0640) continue; // tatweel
    b.write(map[ch] ?? ch);
  }
  return b
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
}

/// "kedi" -> "_ _ _ _", ilk harf istenirse "k _ _ _".
String maskPattern(String word, {bool showFirst = false}) {
  final letters = RegExp(r'[\p{L}\p{N}]', unicode: true);
  final parts = <String>[];
  var first = true;
  for (final ch in word.trim().split('')) {
    if (letters.hasMatch(ch)) {
      parts.add(first && showFirst ? ch.toUpperCase() : '_');
      first = false;
    } else if (ch == ' ') {
      parts.add('  ');
    }
  }
  return parts.join(' ');
}

// ---------- Oyun durumu ----------

enum Phase { handoffSpeak, speak, handoffGuess, guess, result, finished }

class GameController extends ChangeNotifier {
  GameController({
    required this.names,
    required this.rounds,
    required this.speed,
    required this.voice,
  }) : scores = List.filled(names.length, 0);

  static const maxTries = 3;
  static const maxListens = 3;

  final List<String> names;
  final int rounds;
  double speed;
  final bool voice; // true: sadece ses kaydı, kelime yazılmaz
  final List<int> scores;

  int turn = 0;
  Phase phase = Phase.handoffSpeak;

  String secret = '';
  String? originalPath;
  String? reversedPath;

  int listensLeft = maxListens;
  int triesLeft = maxTries;
  bool showLen = false;
  bool showFirst = false;
  bool solved = false;
  int lastPoints = 0;

  int get total => names.length * rounds;
  int get speaker => turn % names.length;
  int get guesser => (turn + 1) % names.length;
  int get hintsUsed => (showLen ? 1 : 0) + (showFirst ? 1 : 0);
  bool get isLastTurn => turn >= total - 1;

  void setSpeed(double v) {
    speed = v;
    notifyListeners();
  }

  void beginSpeak() {
    phase = Phase.speak;
    notifyListeners();
  }

  void submitRecording(String word, String orig, String rev) {
    secret = word.trim();
    originalPath = orig;
    reversedPath = rev;
    listensLeft = maxListens;
    triesLeft = maxTries;
    showLen = false;
    showFirst = false;
    solved = false;
    phase = Phase.handoffGuess;
    notifyListeners();
  }

  void beginGuess() {
    phase = Phase.guess;
    notifyListeners();
  }

  bool useListen() {
    if (listensLeft <= 0) return false;
    listensLeft--;
    notifyListeners();
    return true;
  }

  void useLengthHint() {
    showLen = true;
    notifyListeners();
  }

  void useFirstHint() {
    showLen = true; // ilk harfi göstermek zaten uzunluğu da gösterir
    showFirst = true;
    notifyListeners();
  }

  /// Yazılı modda: doğruysa true.
  bool submitGuess(String guess) {
    final ok = normalizeWord(guess).isNotEmpty &&
        normalizeWord(guess) == normalizeWord(secret);
    _resolve(ok);
    return ok;
  }

  /// Ses modunda: kelimeyi kaydeden kişi doğru/yanlış der.
  void judge(bool ok) => _resolve(ok);

  void _resolve(bool ok) {
    if (ok) {
      solved = true;
      lastPoints =
          voice ? triesLeft.clamp(1, 3) : (3 - hintsUsed).clamp(1, 3);
      scores[guesser] += lastPoints;
      phase = Phase.result;
    } else {
      triesLeft--;
      if (triesLeft <= 0) {
        solved = false;
        lastPoints = 0;
        phase = Phase.result;
      }
    }
    notifyListeners();
  }

  Future<void> nextTurn() async {
    await deleteQuietly(originalPath);
    await deleteQuietly(reversedPath);
    originalPath = null;
    reversedPath = null;
    if (isLastTurn) {
      phase = Phase.finished;
    } else {
      turn++;
      phase = Phase.handoffSpeak;
    }
    notifyListeners();
  }

  List<int> get winners {
    final best = scores.reduce((a, b) => a > b ? a : b);
    return [
      for (var i = 0; i < scores.length; i++)
        if (scores[i] == best) i
    ];
  }

  List<int> get ranking {
    final idx = List<int>.generate(names.length, (i) => i);
    idx.sort((a, b) => scores[b].compareTo(scores[a]));
    return idx;
  }
}
