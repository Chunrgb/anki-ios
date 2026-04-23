import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final double fontSize;
  final bool darkMode;
  final bool showStudyTimer;
  final bool swipeGestures;

  const AppSettings({
    this.fontSize = 18.0,
    this.darkMode = false,
    this.showStudyTimer = true,
    this.swipeGestures = true,
  });
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier());

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = AppSettings(
      fontSize: p.getDouble('font_size') ?? 18.0,
      darkMode: p.getBool('dark_mode') ?? false,
      showStudyTimer: p.getBool('show_study_timer') ?? true,
      swipeGestures: p.getBool('swipe_gestures') ?? true,
    );
  }

  Future<void> setFontSize(double v) async {
    state = AppSettings(fontSize: v, darkMode: state.darkMode, showStudyTimer: state.showStudyTimer, swipeGestures: state.swipeGestures);
    (await SharedPreferences.getInstance()).setDouble('font_size', v);
  }

  Future<void> setDarkMode(bool v) async {
    state = AppSettings(fontSize: state.fontSize, darkMode: v, showStudyTimer: state.showStudyTimer, swipeGestures: state.swipeGestures);
    (await SharedPreferences.getInstance()).setBool('dark_mode', v);
  }

  Future<void> setShowStudyTimer(bool v) async {
    state = AppSettings(fontSize: state.fontSize, darkMode: state.darkMode, showStudyTimer: v, swipeGestures: state.swipeGestures);
    (await SharedPreferences.getInstance()).setBool('show_study_timer', v);
  }

  Future<void> setSwipeGestures(bool v) async {
    state = AppSettings(fontSize: state.fontSize, darkMode: state.darkMode, showStudyTimer: state.showStudyTimer, swipeGestures: v);
    (await SharedPreferences.getInstance()).setBool('swipe_gestures', v);
  }
}
