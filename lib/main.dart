import 'package:flutter/material.dart';
import 'ads.dart';
import 'app_state.dart';
import 'screens.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  runApp(FlipTalkApp(state: state));
  // Reklam SDK'sı açılışı yavaşlatmasın: uygulama göründükten sonra başlat.
  Future.delayed(const Duration(seconds: 3), AdsService.instance.init);
}

class FlipTalkApp extends StatelessWidget {
  const FlipTalkApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Flip Talk',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          locale: Locale(state.lang),
          builder: (context, child) => Directionality(
            textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
