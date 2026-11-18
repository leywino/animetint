import 'dart:convert';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSettings { system, light, dark }

enum GrainBlendMode { softLight, overlay, multiply, screen }

class SettingsProvider with ChangeNotifier {
  final SharedPreferences? prefs;

  SettingsProvider(this.prefs);

  // Tint Settings
  Color get tintColor =>
      Color(prefs?.getInt('tint_color') ?? const Color(0xFFFFB74D).toARGB32());

  set tintColor(Color color) {
    prefs?.setInt('tint_color', color.toARGB32());
    _sync();
  }

  double get tintIntensity => prefs?.getDouble('tint_intensity') ?? 0.15;

  set tintIntensity(double value) {
    prefs?.setDouble('tint_intensity', value);
    _sync();
  }

  // Advanced Noise / Film Grain Settings
  double get noiseIntensity => prefs?.getDouble('noise_intensity') ?? 0.08;

  set noiseIntensity(double value) {
    prefs?.setDouble('noise_intensity', value);
    _sync();
  }

  double get grainScale => prefs?.getDouble('grain_scale') ?? 1.0;

  set grainScale(double value) {
    prefs?.setDouble('grain_scale', value);
    _sync();
  }

  bool get animateGrain => prefs?.getBool('animate_grain') ?? false;

  set animateGrain(bool value) {
    prefs?.setBool('animate_grain', value);
    _sync();
  }

  GrainBlendMode get grainBlendMode =>
      GrainBlendMode.values[prefs?.getInt('grain_blend') ?? 0];

  set grainBlendMode(GrainBlendMode mode) {
    prefs?.setInt('grain_blend', mode.index);
    _sync();
  }

  ThemeSettings get theme =>
      ThemeSettings.values[prefs?.getInt('theme') ?? ThemeSettings.system.index];

  set theme(ThemeSettings t) {
    prefs?.setInt('theme', t.index);
    notifyListeners();
  }

  Map<String, dynamic> toOverlayPayload() => {
        'tintColor': tintColor.toARGB32(),
        'tintIntensity': tintIntensity,
        'noiseIntensity': noiseIntensity,
        'grainScale': grainScale,
        'animateGrain': animateGrain,
        'grainBlend': grainBlendMode.index,
      };

  void applyFromPayload(Map<String, dynamic> data) {
    if (data.containsKey('tintColor')) {
      prefs?.setInt('tint_color', data['tintColor']);
    }
    if (data.containsKey('tintIntensity')) {
      prefs?.setDouble('tint_intensity', (data['tintIntensity'] as num).toDouble());
    }
    if (data.containsKey('noiseIntensity')) {
      prefs?.setDouble('noise_intensity', (data['noiseIntensity'] as num).toDouble());
    }
    if (data.containsKey('grainScale')) {
      prefs?.setDouble('grain_scale', (data['grainScale'] as num).toDouble());
    }
    if (data.containsKey('animateGrain')) {
      prefs?.setBool('animate_grain', data['animateGrain'] as bool);
    }
    if (data.containsKey('grainBlend')) {
      prefs?.setInt('grain_blend', data['grainBlend'] as int);
    }
    notifyListeners();
  }

  Future<void> _sync() async {
    notifyListeners();
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.shareData(jsonEncode(toOverlayPayload()));
    }
  }

  Future<void> resetSettings() async {
    await prefs?.remove('noise_intensity');
    await prefs?.remove('tint_color');
    await prefs?.remove('tint_intensity');
    await prefs?.remove('grain_scale');
    await prefs?.remove('animate_grain');
    await prefs?.remove('grain_blend');
    _sync();
  }
}