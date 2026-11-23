import 'dart:convert';
import 'package:animetint/models/filter_preset.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSettings { system, light, dark }

enum GrainBlendMode { softLight, overlay, multiply, screen }

class SettingsProvider with ChangeNotifier {
  static const customPresetsKey = 'custom_presets';

  final SharedPreferences? prefs;
  List<FilterPreset> _customPresets = [];

  SettingsProvider(this.prefs) {
    loadCustomPresets();
  }

  List<FilterPreset> get customPresets => List.unmodifiable(_customPresets);

  /// Loads valid records independently so a damaged record does not discard
  /// other saved presets.
  void loadCustomPresets() {
    final stored = prefs?.getString(customPresetsKey);
    if (stored == null) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return;

      final loaded = <FilterPreset>[];
      final ids = <String>{};
      final names = <String>{
        for (final preset in FilterPreset.builtIns) preset.name.toLowerCase(),
      };
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          final preset = FilterPreset.fromJson(Map<String, dynamic>.from(item));
          if (preset.isBuiltIn || !ids.add(preset.id)) continue;
          if (!names.add(preset.name.toLowerCase())) continue;
          loaded.add(preset);
        } on Object {
          // Skip only the invalid record.
        }
      }
      _customPresets = loaded;
    } on Object {
      _customPresets = [];
    }
  }

  bool isPresetNameAvailable(String name, {String? excludingId}) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (FilterPreset.builtIns.any(
      (preset) => preset.name.toLowerCase() == normalized,
    )) {
      return false;
    }
    return !_customPresets.any(
      (preset) =>
          preset.id != excludingId && preset.name.toLowerCase() == normalized,
    );
  }

  Future<FilterPreset?> saveCurrentAsPreset(String name) async {
    final trimmedName = name.trim();
    if (!isPresetNameAvailable(trimmedName)) return null;

    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    var id = 'custom-$timestamp';
    var suffix = 1;
    while (_customPresets.any((preset) => preset.id == id)) {
      id = 'custom-$timestamp-${suffix++}';
    }

    final preset = _capturePreset(id, trimmedName);
    _customPresets = [..._customPresets, preset];
    await _persistCustomPresets();
    notifyListeners();
    return preset;
  }

  Future<void> applyPreset(FilterPreset preset) async {
    final writes = <Future<bool>>[];
    if (prefs != null) {
      writes.addAll([
        prefs!.setInt('tint_color', preset.tintColor),
        prefs!.setDouble('tint_intensity', preset.tintIntensity),
        prefs!.setDouble('noise_intensity', preset.noiseIntensity),
        prefs!.setDouble('grain_scale', preset.grainScale),
        prefs!.setBool('animate_grain', preset.animateGrain),
        prefs!.setInt('grain_blend', preset.grainBlendMode),
      ]);
    }
    await Future.wait(writes);
    await _sync();
  }

  Future<bool> updatePreset(String id) async {
    final index = _customPresets.indexWhere((preset) => preset.id == id);
    if (index < 0) return false;
    final existing = _customPresets[index];
    _customPresets[index] = _capturePreset(existing.id, existing.name);
    await _persistCustomPresets();
    notifyListeners();
    return true;
  }

  Future<bool> renamePreset(String id, String newName) async {
    final index = _customPresets.indexWhere((preset) => preset.id == id);
    final trimmedName = newName.trim();
    if (index < 0 || !isPresetNameAvailable(trimmedName, excludingId: id)) {
      return false;
    }
    _customPresets[index] = _customPresets[index].copyWith(name: trimmedName);
    await _persistCustomPresets();
    notifyListeners();
    return true;
  }

  Future<bool> deletePreset(String id) async {
    final index = _customPresets.indexWhere((preset) => preset.id == id);
    if (index < 0 || _customPresets[index].isBuiltIn) return false;
    _customPresets.removeAt(index);
    await _persistCustomPresets();
    notifyListeners();
    return true;
  }

  FilterPreset _capturePreset(String id, String name) => FilterPreset(
    id: id,
    name: name,
    tintColor: tintColor.toARGB32(),
    tintIntensity: tintIntensity,
    noiseIntensity: noiseIntensity,
    grainScale: grainScale,
    animateGrain: animateGrain,
    grainBlendMode: grainBlendMode.index,
  );

  Future<void> _persistCustomPresets() async {
    final json = jsonEncode(
      _customPresets.map((preset) => preset.toJson()).toList(),
    );
    await prefs?.setString(customPresetsKey, json);
  }

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
      ThemeSettings.values[prefs?.getInt('theme') ??
          ThemeSettings.system.index];

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
      prefs?.setDouble(
        'tint_intensity',
        (data['tintIntensity'] as num).toDouble(),
      );
    }
    if (data.containsKey('noiseIntensity')) {
      prefs?.setDouble(
        'noise_intensity',
        (data['noiseIntensity'] as num).toDouble(),
      );
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
