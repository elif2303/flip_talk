import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Kayıt + TTS + oynatma.
class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _rec = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final List<String> _rendered = [];

  AudioService() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  // ---------------- Kayıt ----------------
  /// Kaydı başlatır. İzin yoksa false döner.
  /// Gürültü bastırma / otomatik kazanç KAPALI: konuşmayı bozup çızırtı yapıyordu.
  Future<bool> startRecording() async {
    if (!await _rec.hasPermission()) return false;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}ft_${DateTime.now().microsecondsSinceEpoch}.wav';
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 48000,
        numChannels: 1,
        noiseSuppress: false,
        autoGain: false,
        echoCancel: false,
      ),
      path: path,
    );
    return true;
  }

  Future<String?> stopRecording() => _rec.stop();

  // ---------------- TTS ----------------
  static const _locales = {
    'en': 'en-US',
    'tr': 'tr-TR',
    'de': 'de-DE',
    'ar': 'ar',
  };

  /// Son hatanın kısa açıklaması (ekranda göstermek için).
  String lastError = '';

  /// Seçilen dile ait sesleri döndürür (çevrimdışı olanlar önce).
  Future<List<Map<String, String>>> _voicesFor(String lang) async {
    final result = <Map<String, String>>[];
    try {
      final raw = await _tts.getVoices;
      if (raw is List) {
        for (final v in raw) {
          if (v is! Map) continue;
          final name = '${v['name'] ?? ''}';
          final locRaw = '${v['locale'] ?? ''}';
          final loc = locRaw.replaceAll('_', '-').toLowerCase();
          if (name.isEmpty) continue;
          if (loc == lang || loc.startsWith('$lang-')) {
            result.add({'name': name, 'locale': locRaw});
          }
        }
        result.sort((a, b) {
          int score(Map<String, String> m) =>
              m['name']!.toLowerCase().contains('network') ? 1 : 0;
          return score(a).compareTo(score(b));
        });
      }
    } catch (_) {}
    return result;
  }

  Future<String?> _trySynth(String text, String path) async {
    try {
      final r = await _tts.synthesizeToFile(text, path, true);
      if (r != 1) {
        lastError = 'synth=$r';
        return null;
      }
      final f = File(path);
      if (!await f.exists() || await f.length() < 1000) {
        lastError = 'empty file';
        return null;
      }
      return path;
    } catch (e) {
      lastError = '$e';
      return null;
    }
  }

  /// Yazılan kelimeyi WAV dosyasına okutur. Önce dile uygun sesleri tek tek
  /// dener, olmazsa varsayılan sesle dener. Başarısızsa null döner.
  Future<String?> synthesize(String text, String lang) async {
    lastError = '';
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}${Platform.pathSeparator}ft_${DateTime.now().microsecondsSinceEpoch}.wav';
      await _tts.awaitSynthCompletion(true);
      await _tts.setSpeechRate(0.4);
      await _tts.setPitch(1.0);
      final code = _locales[lang] ?? 'en-US';
      try {
        await _tts.setLanguage(code);
      } catch (_) {}

      final voices = await _voicesFor(lang);
      for (final v in voices.take(4)) {
        try {
          await _tts.setVoice(v);
        } catch (_) {
          continue;
        }
        final ok = await _trySynth(text, path);
        if (ok != null) return ok;
      }
      // Son çare: yalnızca dil ayarı, özel ses seçmeden.
      try {
        await _tts.setLanguage(code);
      } catch (_) {}
      return await _trySynth(text, path);
    } catch (e) {
      lastError = '$e';
      return null;
    }
  }

  // ---------------- Oynatma ----------------
  /// Hız değişimini oynatıcıya bırakmadan, dosyayı kendimiz yeniden örnekleyip
  /// 1× oynatırız (oynatıcının zaman uzatması çızırtı yapabiliyor).
  Future<void> playSpeed(String path, double speed) async {
    final p = await renderSpeed(path, speed);
    if (p != path) _rendered.add(p);
    await play(p);
  }

  Future<void> play(String path) async {
    await _player.stop();
    await _player.setPlaybackRate(1.0);
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlaying() => _player.stop();

  Future<void> clearRendered() async {
    for (final p in _rendered) {
      await deleteQuietly(p);
    }
    _rendered.clear();
  }

  Future<void> dispose() async {
    await clearRendered();
    await _player.dispose();
    await _tts.stop();
    await _rec.dispose();
  }
}

Future<void> deleteQuietly(String? path) async {
  if (path == null) return;
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}

// =====================================================================
// WAV işleme
// =====================================================================
class _Wav {
  _Wav(this.channels, this.bits, this.rate, this.dataStart, this.dataLen);
  final int channels, bits, rate, dataStart, dataLen;
  int get frame => channels * (bits ~/ 8);
  int get frames => dataLen ~/ frame;

  static _Wav parse(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    if (bytes.length < 44 || String.fromCharCodes(bytes, 0, 4) != 'RIFF') {
      throw Exception('Not a WAV file');
    }
    var channels = 1, bits = 16, rate = 44100;
    var off = 12;
    while (off + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes, off, off + 4);
      var size = bd.getUint32(off + 4, Endian.little);
      final body = off + 8;
      if (id == 'fmt ') {
        channels = bd.getUint16(body + 2, Endian.little);
        rate = bd.getUint32(body + 4, Endian.little);
        bits = bd.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        final remaining = bytes.length - body;
        if (size == 0 || size > remaining) size = remaining;
        return _Wav(channels, bits, rate, body, size);
      }
      off = body + size + (size & 1);
    }
    throw Exception('No data chunk');
  }
}

String _siblingPath(String inPath, String prefix) {
  final slash = inPath.lastIndexOf(RegExp(r'[\\/]'));
  final dir = slash >= 0 ? inPath.substring(0, slash + 1) : '';
  final name = slash >= 0 ? inPath.substring(slash + 1) : inPath;
  return '$dir$prefix$name';
}

/// WAV'ı tersine çevirir. Önce temizler: DC kaydırmasını ve çok alçak
/// gürültüyü atar, sessizliği kırpar, sesi normalleştirir, uçlara yumuşak
/// fade uygular. Yeni dosyanın yolunu döner.
Future<String> reverseWav(String inPath) async {
  final bytes = await File(inPath).readAsBytes();
  final w = _Wav.parse(bytes);
  final bd = ByteData.sublistView(bytes);
  final frame = w.frame;
  final ds = w.dataStart;

  var s = 0, e = w.frames;
  if (w.bits == 16) {
    var peak = 0;
    for (var i = 0; i < w.frames; i++) {
      final v = bd.getInt16(ds + i * frame, Endian.little).abs();
      if (v > peak) peak = v;
    }
    final thr = math.max(300, (peak * 0.05).round());
    var first = -1, last = -1;
    for (var i = 0; i < w.frames; i++) {
      if (bd.getInt16(ds + i * frame, Endian.little).abs() > thr) {
        if (first < 0) first = i;
        last = i;
      }
    }
    if (first >= 0) {
      final pad = (w.rate * 0.10).round();
      s = (first - pad).clamp(0, w.frames);
      e = (last + pad).clamp(0, w.frames);
      if (e - s < w.rate ~/ 10) {
        s = 0;
        e = w.frames;
      }
    }
  }
  final n = e - s;

  final out = Uint8List(ds + n * frame);
  out.setRange(0, ds, bytes);
  final ob = ByteData.sublistView(out);
  ob.setUint32(4, out.length - 8, Endian.little);
  ob.setUint32(ds - 4, n * frame, Endian.little);

  if (w.bits == 16) {
    final ch = w.channels;
    final chans = <Float64List>[];
    final a = 1 / (1 + 2 * math.pi * 90 / w.rate); // ~90 Hz yüksek geçiren
    var peak = 0.0;
    for (var c = 0; c < ch; c++) {
      final x = Float64List(n);
      var sum = 0.0;
      for (var i = 0; i < n; i++) {
        final v =
            bd.getInt16(ds + (s + i) * frame + c * 2, Endian.little).toDouble();
        x[i] = v;
        sum += v;
      }
      final mean = n > 0 ? sum / n : 0.0;
      var prevX = 0.0, prevY = 0.0;
      for (var i = 0; i < n; i++) {
        final xi = x[i] - mean;
        final y = a * (prevY + xi - prevX);
        prevX = xi;
        prevY = y;
        x[i] = y;
        if (y.abs() > peak) peak = y.abs();
      }
      chans.add(x);
    }
    final gain = peak > 0 ? math.min(0.89 * 32767 / peak, 6.0) : 1.0;
    final fadeN = math.max(1, math.min((w.rate * 0.03).round(), n ~/ 4));
    for (var i = 0; i < n; i++) {
      final k = math.min(i, n - 1 - i);
      final g = k < fadeN ? 0.5 - 0.5 * math.cos(math.pi * k / fadeN) : 1.0;
      for (var c = 0; c < ch; c++) {
        final v = (chans[c][n - 1 - i] * gain * g).round().clamp(-32768, 32767);
        ob.setInt16(ds + i * frame + c * 2, v, Endian.little);
      }
    }
  } else {
    for (var i = 0; i < n; i++) {
      final src = ds + (s + n - 1 - i) * frame;
      final dst = ds + i * frame;
      out.setRange(dst, dst + frame, bytes, src);
    }
  }

  final outPath = _siblingPath(inPath, 'rev_');
  await File(outPath).writeAsBytes(out, flush: true);
  return outPath;
}

/// Perdeyi (ses tonunu) koruyarak hızı değiştirir (WSOLA zaman uzatma).
/// speed < 1 = daha yavaş. Yeni dosyanın yolunu döner.
Future<String> renderSpeed(String path, double speed) async {
  if ((speed - 1.0).abs() < 0.01) return path;
  final bytes = await File(path).readAsBytes();
  final w = _Wav.parse(bytes);
  if (w.bits != 16 || w.frames < 2) return path;
  final bd = ByteData.sublistView(bytes);
  final ds = w.dataStart;
  final frame = w.frame;
  final ch = w.channels;
  final len = w.frames;

  var nWin = (w.rate * 0.04).round();
  nWin += nWin % 2;
  final hs = nWin ~/ 2; // sentez adımı
  final ha = hs * speed; // analiz adımı
  final delta = (w.rate * 0.012).round(); // arama aralığı
  final m = (len / speed).floor();
  final k = (m / hs).ceil() + 1;

  // Kanalları oku (sıfırla doldurulmuş).
  final pad = nWin + 2 * delta + hs + 8;
  final xs = <Float64List>[];
  for (var c = 0; c < ch; c++) {
    final x = Float64List(len + pad);
    for (var i = 0; i < len; i++) {
      x[i] = bd.getInt16(ds + i * frame + c * 2, Endian.little).toDouble();
    }
    xs.add(x);
  }
  final win = Float64List(nWin);
  for (var i = 0; i < nWin; i++) {
    win[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / nWin);
  }

  final outs = [for (var c = 0; c < ch; c++) Float64List(k * hs + nWin)];
  final x0 = xs[0];
  var prev = 0;
  for (var f = 0; f < k; f++) {
    if (f * hs >= m) break;
    final nominal = (f * ha).round();
    var pos = 0;
    if (f > 0) {
      final tgt = prev + hs;
      final lo = math.max(0, nominal - delta);
      final hi = math.min(nominal + delta, len - 1);
      var best = double.infinity;
      pos = math.min(nominal, math.max(0, len - 1));
      for (var cnd = lo; cnd <= hi; cnd++) {
        var sum = 0.0;
        for (var i = 0; i < hs; i += 2) {
          final d = x0[cnd + i] - x0[tgt + i];
          sum += d < 0 ? -d : d;
          if (sum >= best) break;
        }
        if (sum < best) {
          best = sum;
          pos = cnd;
        }
      }
    }
    for (var c = 0; c < ch; c++) {
      final x = xs[c];
      final o = outs[c];
      final base = f * hs;
      for (var i = 0; i < nWin; i++) {
        o[base + i] += win[i] * x[pos + i];
      }
    }
    prev = pos;
  }

  final out = Uint8List(ds + m * frame);
  out.setRange(0, ds, bytes);
  final ob = ByteData.sublistView(out);
  ob.setUint32(4, out.length - 8, Endian.little);
  ob.setUint32(ds - 4, m * frame, Endian.little);
  for (var i = 0; i < m; i++) {
    for (var c = 0; c < ch; c++) {
      final v = outs[c][i].round().clamp(-32768, 32767);
      ob.setInt16(ds + i * frame + c * 2, v, Endian.little);
    }
  }
  final outPath = _siblingPath(path, 'spd${(speed * 100).round()}_');
  await File(outPath).writeAsBytes(out, flush: true);
  return outPath;
}
