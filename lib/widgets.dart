import 'package:flutter/material.dart';
import 'app_state.dart';
import 'strings.dart';
import 'theme.dart';

/// Ortalanmış, tam genişlikli, taşarsa kaydırılan sayfa gövdesi.
class ScrollPage extends StatelessWidget {
  const ScrollPage({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight - 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Renkli, yuvarlak bilgi kartı.
class FunCard extends StatelessWidget {
  const FunCard({super.key, required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: FT.purple.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );
}

/// Basılı tutarak kayıt düğmesi.
class HoldMicButton extends StatelessWidget {
  const HoldMicButton({
    super.key,
    required this.recording,
    required this.onStart,
    required this.onEnd,
    required this.label,
  });
  final bool recording;
  final VoidCallback onStart;
  final VoidCallback onEnd;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Listener(
          onPointerDown: (_) => onStart(),
          onPointerUp: (_) => onEnd(),
          onPointerCancel: (_) => onEnd(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: recording ? 150 : 130,
            height: recording ? 150 : 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: recording
                    ? [FT.pink, FT.yellow]
                    : [FT.purple, FT.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (recording ? FT.pink : FT.purple)
                      .withValues(alpha: 0.45),
                  blurRadius: recording ? 30 : 18,
                  spreadRadius: recording ? 6 : 0,
                ),
              ],
            ),
            child: Icon(
              recording ? Icons.graphic_eq_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

Future<void> showLanguageDialog(BuildContext context) {
  final app = context.app;
  return showDialog<void>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(app.t('language')),
      children: [
        for (final code in supportedLangs)
          SimpleDialogOption(
            onPressed: () {
              app.setLang(code);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  code == app.lang
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: FT.purple,
                ),
                const SizedBox(width: 12),
                Text(langNames[code]!, style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
      ],
    ),
  );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
