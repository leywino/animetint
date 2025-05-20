import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSettings { system, light, dark }

class SettingsProvider with ChangeNotifier {
  SharedPreferences? prefs;

  SettingsProvider(this.prefs);

  double get noiseIntensity {
    return prefs?.getDouble('noise_intensity') ?? 0.1;
  }

  set noiseIntensity(double value) {
    prefs?.setDouble('noise_intensity', value);
    notifyListeners();
  }

  Color get tintColor {
    int colorValue = prefs?.getInt('tint_color') ?? Colors.yellow.toARGB32();
    return Color(colorValue);
  }

  set tintColor(Color color) {
    prefs?.setInt('tint_color', color.toARGB32());
    notifyListeners();
  }

  double get tintIntensity {
    return prefs?.getDouble('tint_intensity') ?? 0.1;
  }

  set tintIntensity(double value) {
    prefs?.setDouble('tint_intensity', value);
    notifyListeners();
  }

  ThemeSettings get theme {
    return ThemeSettings.values[prefs?.getInt('theme') ??
        ThemeSettings.system.index];
  }

  set theme(ThemeSettings t) {
    prefs?.setInt('theme', t.index);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    await prefs?.remove('noise_intensity');
    await prefs?.remove('tint_color');
    await prefs?.remove('tint_intensity');
    await prefs?.remove('use_overlay');
    await prefs?.remove('theme');
    notifyListeners();
  }
}
