import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'strings.dart';

class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.lang, this.speed, this.rounds, this.names, this.voice);

  final SharedPreferences _prefs;
  String lang;
  double speed;
  int rounds;
  List<String> names;
  bool voice;

  static Future<AppState> load() async {
    final p = await SharedPreferences.getInstance();
    var lang = p.getString('lang');
    if (lang == null || !supportedLangs.contains(lang)) {
      final sys = PlatformDispatcher.instance.locale.languageCode;
      lang = supportedLangs.contains(sys) ? sys : 'en';
    }
    return AppState._(
      p,
      lang,
      p.getDouble('speed') ?? 0.75,
      p.getInt('rounds') ?? 1,
      p.getStringList('names') ?? <String>[],
      p.getBool('voice') ?? false,
    );
  }

  bool get isRtl => lang == 'ar';

  String t(String key, [Map<String, Object> args = const {}]) =>
      tr(lang, key, args);

  void setLang(String l) {
    lang = l;
    _prefs.setString('lang', l);
    notifyListeners();
  }

  void saveSettings({double? speed, int? rounds, List<String>? names, bool? voice}) {
    if (speed != null) {
      this.speed = speed;
      _prefs.setDouble('speed', speed);
    }
    if (rounds != null) {
      this.rounds = rounds;
      _prefs.setInt('rounds', rounds);
    }
    if (names != null) {
      this.names = names;
      _prefs.setStringList('names', names);
    }
    if (voice != null) {
      this.voice = voice;
      _prefs.setBool('voice', voice);
    }
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppContext on BuildContext {
  AppState get app => AppScope.of(this);
  String s(String key, [Map<String, Object> args = const {}]) =>
      AppScope.of(this).t(key, args);
}
