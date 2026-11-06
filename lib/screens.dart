import 'dart:async';

import 'package:flutter/material.dart';

import 'ads.dart';
import 'app_state.dart';
import 'audio_service.dart';
import 'game.dart';
import 'theme.dart';
import 'widgets.dart';

// =====================================================================
// HOME
// =====================================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ScrollPage(
            children: [
              Container(
                height: 150,
                alignment: Alignment.center,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [FT.purple, FT.pink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: Colors.white, size: 72),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.s('appName'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  color: FT.purple,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.s('tagline'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: FT.pink,
                ),
              ),
              const SizedBox(height: 24),
              FunCard(
                child: Text(
                  context.s('howTo'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SetupScreen()),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 30),
                label: Text(context.s('play')),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: context.app.isRtl ? null : 8,
            left: context.app.isRtl ? 8 : null,
            child: SafeArea(
              child: ActionChip(
                avatar: const Icon(Icons.language, size: 18),
                label: Text(langNamesShort(context.app.lang)),
                onPressed: () => showLanguageDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String langNamesShort(String code) => code.toUpperCase();
}

// =====================================================================
// SETUP
// =====================================================================
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late List<TextEditingController> _ctrls;
  late int _rounds;
  late double _speed;
  late bool _voice;

  @override
  void initState() {
    super.initState();
    final app = context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
    _rounds = app.rounds;
    _speed = app.speed;
    _voice = app.voice;
    final saved = app.names;
    final count = saved.length.clamp(2, 8);
    _ctrls = List.generate(
      count,
      (i) => TextEditingController(text: i < saved.length ? saved[i] : ''),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    final app = context.app;
    final names = <String>[
      for (var i = 0; i < _ctrls.length; i++)
        _ctrls[i].text.trim().isEmpty
            ? app.t('playerN', {'n': i + 1})
            : _ctrls[i].text.trim(),
    ];
    app.saveSettings(
      speed: _speed,
      rounds: _rounds,
      voice: _voice,
      names: [for (final c in _ctrls) c.text.trim()],
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
            names: names, rounds: _rounds, speed: _speed, voice: _voice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.s('newGame'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(context.s('players'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (var i = 0; i < _ctrls.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrls[i],
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: context.s('playerN', {'n': i + 1}),
                          prefixIcon: CircleAvatar(
                            radius: 14,
                            backgroundColor: colorFor(i),
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    color: onColor(colorFor(i)),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    if (_ctrls.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          _ctrls.removeAt(i).dispose();
                        }),
                      ),
                  ],
                ),
              ),
            if (_ctrls.length < 8)
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _ctrls.add(TextEditingController())),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(context.s('addPlayer')),
              ),
            const SizedBox(height: 24),
            Text(context.s('modeTitle'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.keyboard),
                    label: Text(context.s('modeText'))),
                ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.headphones),
                    label: Text(context.s('modeVoice'))),
              ],
              selected: {_voice},
              onSelectionChanged: (s) => setState(() => _voice = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              context.s(_voice ? 'modeVoiceDesc' : 'modeTextDesc'),
              style: TextStyle(
                  fontSize: 14, color: FT.ink.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 24),
            Text(context.s('rounds'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
              ],
              selected: {_rounds},
              onSelectionChanged: (s) => setState(() => _rounds = s.first),
            ),
            const SizedBox(height: 24),
            Text(context.s('speed'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SpeedPicker(
              value: _speed,
              onChanged: (v) => setState(() => _speed = v),
            ),
            const SizedBox(height: 30),
            FilledButton(onPressed: _start, child: Text(context.s('start'))),
          ],
        ),
      ),
    );
  }
}

class SpeedPicker extends StatelessWidget {
  const SpeedPicker({super.key, required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<double>(
      segments: const [
        ButtonSegment(value: 0.5, label: Text('0.5×')),
        ButtonSegment(value: 0.75, label: Text('0.75×')),
        ButtonSegment(value: 1.0, label: Text('1×')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

// =====================================================================
// GAME
// =====================================================================
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.names,
    required this.rounds,
    required this.speed,
    required this.voice,
  });
  final List<String> names;
  final int rounds;
  final double speed;
  final bool voice;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController game;
  final AudioService audio = AudioService();

  @override
  void initState() {
    super.initState();
    game = GameController(
      names: widget.names,
      rounds: widget.rounds,
      speed: widget.speed,
      voice: widget.voice,
    );
  }

  @override
  void dispose() {
    deleteQuietly(game.originalPath);
    deleteQuietly(game.reversedPath);
    game.dispose();
    audio.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() {
      game.dispose();
      game = GameController(
        names: widget.names,
        rounds: widget.rounds,
        speed: widget.speed,
      voice: widget.voice,
      );
    });
  }

  Future<void> _confirmQuit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.s('quit')),
        content: Text(context.s('quitMsg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.s('no'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.s('yes'))),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: ListenableBuilder(
        listenable: game,
        builder: (context, _) {
          final Widget page;
          switch (game.phase) {
            case Phase.handoffSpeak:
              page = HandoffPage(
                key: ValueKey('hs${game.turn}'),
                title: context.s('passTo'),
                name: game.names[game.speaker],
                colorIndex: game.speaker,
                subtitle: context.s(
                    'turnOf', {'a': game.turn + 1, 'b': game.total}),
                onReady: game.beginSpeak,
              );
            case Phase.speak:
              page = SpeakPage(
                key: ValueKey('sp${game.turn}'),
                game: game,
                audio: audio,
              );
            case Phase.handoffGuess:
              page = HandoffPage(
                key: ValueKey('hg${game.turn}'),
                title: context.s('passTo'),
                name: game.names[game.guesser],
                colorIndex: game.guesser,
                subtitle: context.s(
                    'turnOf', {'a': game.turn + 1, 'b': game.total}),
                onReady: game.beginGuess,
              );
            case Phase.guess:
              page = GuessPage(
                key: ValueKey('gu${game.turn}'),
                game: game,
                audio: audio,
              );
            case Phase.result:
              page = ResultPage(
                key: ValueKey('re${game.turn}'),
                game: game,
                audio: audio,
              );
            case Phase.finished:
              page = FinishedPage(
                game: game,
                onAgain: _restart,
                onHome: () => Navigator.pop(context),
              );
          }
          return Scaffold(
            appBar: game.phase == Phase.finished
                ? null
                : AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _confirmQuit,
                    ),
                    title: Text(context.s(
                        'turnOf', {'a': game.turn + 1, 'b': game.total})),
                  ),
            body: page,
          );
        },
      ),
    );
  }
}

// 8 oyuncuya kadar her oyuncunun kendi rengi var.
const _avatarColors = [
  FT.purple,
  FT.pink,
  FT.mint,
  FT.yellow,
  Color(0xFFFF8A3D), // turuncu
  Color(0xFF2F80ED), // mavi
  Color(0xFFA3D63B), // limon yeşili
  Color(0xFF8D6E63), // kahverengi
];
Color colorFor(int i) => _avatarColors[i % _avatarColors.length];

/// Renk açıksa koyu, koyuysa beyaz yazı.
Color onColor(Color c) => c.computeLuminance() > 0.45 ? FT.ink : Colors.white;

// ---------------------------------------------------------------------
class HandoffPage extends StatelessWidget {
  const HandoffPage({
    super.key,
    required this.title,
    required this.name,
    required this.colorIndex,
    required this.subtitle,
    required this.onReady,
  });
  final String title, name, subtitle;
  final int colorIndex;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final c = colorFor(colorIndex);
    return ScrollPage(
      children: [
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: onColor(c),
            ),
          ),
        ),
        const SizedBox(height: 36),
        FilledButton(onPressed: onReady, child: Text(context.s('imReady'))),
      ],
    );
  }
}

// ---------------------------------------------------------------------
class SpeakPage extends StatefulWidget {
  const SpeakPage({super.key, required this.game, required this.audio});
  final GameController game;
  final AudioService audio;

  @override
  State<SpeakPage> createState() => _SpeakPageState();
}

class _SpeakPageState extends State<SpeakPage> {
  final _word = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  // ses modu
  bool _recording = false;
  String? _orig;
  DateTime? _startedAt;
  Timer? _limit;

  @override
  void dispose() {
    _limit?.cancel();
    _word.dispose();
    if (_recording) widget.audio.stopRecording();
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy || _recording) return;
    widget.audio.stopPlaying();
    final denied = context.s('micDenied');
    final ok = await widget.audio.startRecording();
    if (!mounted) return;
    if (!ok) {
      toast(context, denied);
      return;
    }
    setState(() {
      _recording = true;
      _startedAt = DateTime.now();
    });
    _limit = Timer(const Duration(seconds: 6), _end);
  }

  Future<void> _end() async {
    if (!_recording) return;
    _limit?.cancel();
    final short = context.s('tooShort');
    final ms = DateTime.now().difference(_startedAt!).inMilliseconds;
    final path = await widget.audio.stopRecording();
    if (!mounted) return;
    setState(() => _recording = false);
    if (ms < 400 || path == null) {
      toast(context, short);
      await deleteQuietly(path);
      return;
    }
    await deleteQuietly(_orig);
    setState(() => _orig = path);
  }

  Future<void> _send() async {
    final voice = widget.game.voice;
    final word = _word.text.trim();
    if (!voice && word.isEmpty) {
      toast(context, context.s('needWord'));
      return;
    }
    if (voice && _orig == null) {
      toast(context, context.s('needRecording'));
      return;
    }
    final lang = context.app.lang;
    final err = context.s('ttsError');
    setState(() => _busy = true);
    String? orig = _orig;
    try {
      if (!voice) {
        orig = await widget.audio.synthesize(word, lang);
        if (orig == null) throw Exception('tts');
      }
      final rev = await reverseWav(orig!);
      if (!mounted) return;
      widget.game.submitRecording(voice ? '' : word, orig, rev);
    } catch (e) {
      await deleteQuietly(orig);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _orig = null;
      });
      toast(context, voice ? 'Error: $e' : '$err (${widget.audio.lastError})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final voice = g.voice;
    return ScrollPage(
      children: [
        Text(
          context.s('speakTitle', {'name': g.names[g.speaker]}),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        if (!voice) ...[
          TextField(
            controller: _word,
            obscureText: _hidden,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              labelText: context.s('secretLabel'),
              suffixIcon: IconButton(
                icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hidden = !_hidden),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.s('speakTip'),
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: FT.ink.withValues(alpha: 0.7)),
          ),
        ] else ...[
          Center(
            child: HoldMicButton(
              recording: _recording,
              onStart: _start,
              onEnd: _end,
              label: _recording
                  ? context.s('recording')
                  : (_orig != null
                      ? context.s('recorded')
                      : context.s('holdToRecord')),
            ),
          ),
          const SizedBox(height: 14),
          if (_orig != null && !_recording)
            OutlinedButton.icon(
              onPressed: () => widget.audio.play(_orig!),
              icon: const Icon(Icons.hearing),
              label: Text(context.s('listenOriginal')),
            ),
          const SizedBox(height: 14),
          Text(
            context.s('voiceTip'),
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: FT.ink.withValues(alpha: 0.7)),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3))
              : Text(context.s('send')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
class GuessPage extends StatefulWidget {
  const GuessPage({super.key, required this.game, required this.audio});
  final GameController game;
  final AudioService audio;

  @override
  State<GuessPage> createState() => _GuessPageState();
}

class _GuessPageState extends State<GuessPage> {
  final _guess = TextEditingController();
  String? _msg;

  // Taklit
  bool _mRec = false;
  bool _mBusy = false;
  String? _mOrig;
  String? _mRev;
  DateTime? _mStart;
  Timer? _mLimit;

  @override
  void dispose() {
    _mLimit?.cancel();
    if (_mRec) widget.audio.stopRecording();
    deleteQuietly(_mOrig);
    deleteQuietly(_mRev);
    _guess.dispose();
    widget.audio.stopPlaying();
    widget.audio.clearRendered();
    super.dispose();
  }

  Future<void> _mimicStart() async {
    if (_mRec || _mBusy) return;
    widget.audio.stopPlaying();
    final denied = context.s('micDenied');
    final ok = await widget.audio.startRecording();
    if (!mounted) {
      await widget.audio.stopRecording();
      return;
    }
    if (!ok) {
      toast(context, denied);
      return;
    }
    setState(() {
      _mRec = true;
      _mStart = DateTime.now();
    });
    _mLimit = Timer(const Duration(seconds: 6), _mimicEnd);
  }

  Future<void> _mimicEnd() async {
    if (!_mRec) return;
    _mLimit?.cancel();
    final short = context.s('tooShort');
    final ms = DateTime.now().difference(_mStart!).inMilliseconds;
    final path = await widget.audio.stopRecording();
    if (!mounted) return;
    setState(() => _mRec = false);
    if (ms < 400 || path == null) {
      toast(context, short);
      await deleteQuietly(path);
      return;
    }
    setState(() => _mBusy = true);
    try {
      await deleteQuietly(_mOrig);
      await deleteQuietly(_mRev);
      final rev = await reverseWav(path);
      if (!mounted) return;
      setState(() {
        _mOrig = path;
        _mRev = rev;
        _mBusy = false;
      });
      widget.audio.play(rev); // taklidi hemen tersten çal
    } catch (_) {
      if (mounted) setState(() => _mBusy = false);
    }
  }

  void _listen() {
    final g = widget.game;
    if (g.reversedPath == null || !g.useListen()) return;
    widget.audio.playSpeed(g.reversedPath!, g.speed);
  }

  void _judge(bool right) {
    final g = widget.game;
    widget.audio.stopPlaying();
    g.judge(right);
    if (!right && g.phase == Phase.guess) {
      setState(() => _msg = context.s('wrongTry', {'n': g.triesLeft}));
    }
  }

  void _check() {
    final g = widget.game;
    if (_guess.text.trim().isEmpty) return;
    widget.audio.stopPlaying();
    final ok = g.submitGuess(_guess.text);
    if (!ok && g.phase == Phase.guess) {
      setState(() {
        _msg = context.s('wrongTry', {'n': g.triesLeft});
        _guess.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final mask = (g.showLen)
        ? maskPattern(g.secret, showFirst: g.showFirst)
        : null;
    return ScrollPage(
      children: [
        Text(
          context.s('guessTitle', {'name': g.names[g.guesser]}),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: FT.pink,
            minimumSize: const Size.fromHeight(72),
          ),
          onPressed: g.listensLeft > 0 ? _listen : null,
          icon: const Icon(Icons.fast_rewind_rounded, size: 32),
          label: Text(context.s('listen')),
        ),
        const SizedBox(height: 6),
        Text(
          context.s('listensLeft', {'n': g.listensLeft}),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        SpeedPicker(value: g.speed, onChanged: g.setSpeed),
        const SizedBox(height: 18),
        FunCard(
          child: Column(
            children: [
              Text(context.s('mimicTitle'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                context.s('mimicDesc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: FT.ink.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 14),
              HoldMicButton(
                recording: _mRec,
                onStart: _mimicStart,
                onEnd: _mimicEnd,
                label: _mRec
                    ? context.s('recording')
                    : context.s('mimicHold'),
              ),
              if (_mBusy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              if (_mRev != null && !_mRec && !_mBusy) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => widget.audio.play(_mRev!),
                  icon: const Icon(Icons.replay),
                  label: Text(context.s('mimicPlay')),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (g.voice) ...[
          const SizedBox(height: 18),
          Text(
            context.s('voiceGuessTip'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: FT.mint),
                  onPressed: () => _judge(true),
                  child: Text(context.s('judgeRight')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: FT.pink),
                  onPressed: () => _judge(false),
                  child: Text(context.s('judgeWrong')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _msg ?? context.s('triesLeft', {'n': g.triesLeft}),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _msg != null ? FT.pink : FT.ink,
            ),
          ),
        ] else ...[
        FunCard(
          child: Column(
            children: [
              Text(context.s('hints'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: g.showLen ? null : g.useLengthHint,
                      child: Text(context.s('hintLength'),
                          textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: g.showFirst ? null : g.useFirstHint,
                      child: Text(context.s('hintFirst'),
                          textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
              if (mask != null) ...[
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    mask,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: FT.purple,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _guess,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _check(),
          decoration: InputDecoration(labelText: context.s('yourGuess')),
        ),
        const SizedBox(height: 8),
        Text(
          _msg ?? context.s('triesLeft', {'n': g.triesLeft}),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _msg != null ? FT.pink : FT.ink,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _check, child: Text(context.s('check'))),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------
class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.game, required this.audio});
  final GameController game;
  final AudioService audio;

  @override
  Widget build(BuildContext context) {
    final g = game;
    final good = g.solved;
    return ScrollPage(
      children: [
        Icon(
          good ? Icons.celebration_rounded : Icons.sentiment_dissatisfied,
          size: 80,
          color: good ? FT.mint : FT.pink,
        ),
        const SizedBox(height: 8),
        Text(
          good ? context.s('correct') : context.s('wrong'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: good ? FT.mint : FT.pink,
          ),
        ),
        const SizedBox(height: 14),
        if (g.voice && good)
          Text(
            context.s('points', {'n': g.lastPoints}),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        if (!g.voice)
        FunCard(
          child: Column(
            children: [
              Text(context.s('theWordWas')),
              const SizedBox(height: 6),
              Text(
                g.secret,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: FT.purple),
              ),
              if (good) ...[
                const SizedBox(height: 8),
                Text(
                  context.s('points', {'n': g.lastPoints}),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            if (g.originalPath != null) audio.play(g.originalPath!);
          },
          icon: const Icon(Icons.volume_up_rounded),
          label: Text(context.s('playOriginal')),
        ),
        const SizedBox(height: 18),
        ScoreList(game: g),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            audio.stopPlaying();
            await AdsService.instance.maybeShowInterstitial();
            g.nextTurn();
          },
          child: Text(g.isLastTurn
              ? context.s('finish')
              : context.s('nextTurn')),
        ),
        const SizedBox(height: 12),
        const BannerSlot(),
      ],
    );
  }
}

class ScoreList extends StatelessWidget {
  const ScoreList({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return FunCard(
      child: Column(
        children: [
          Text(context.s('scores'),
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final i in game.ranking)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(radius: 8, backgroundColor: colorFor(i)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(game.names[i],
                        style: const TextStyle(fontSize: 17)),
                  ),
                  Text('${game.scores[i]} ${context.s('pts')}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
class FinishedPage extends StatelessWidget {
  const FinishedPage({
    super.key,
    required this.game,
    required this.onAgain,
    required this.onHome,
  });
  final GameController game;
  final VoidCallback onAgain, onHome;

  @override
  Widget build(BuildContext context) {
    final w = game.winners;
    final title = w.length == 1
        ? context.s('winner', {'name': game.names[w.first]})
        : context.s('tie');
    return Scaffold(
      body: ScrollPage(
        children: [
          const Icon(Icons.emoji_events_rounded, size: 90, color: FT.yellow),
          const SizedBox(height: 8),
          Text(context.s('gameOver'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w900, color: FT.purple)),
          const SizedBox(height: 20),
          ScoreList(game: game),
          const SizedBox(height: 24),
          FilledButton(onPressed: onAgain, child: Text(context.s('playAgain'))),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onHome, child: Text(context.s('home'))),
          const SizedBox(height: 12),
          const BannerSlot(),
        ],
      ),
    );
  }
}
