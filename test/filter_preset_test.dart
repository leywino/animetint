import 'dart:convert';

import 'package:animetint/controller/settings_provider.dart';
import 'package:animetint/models/filter_preset.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preset JSON round trips the complete filter configuration', () {
    const preset = FilterPreset(
      id: 'custom-1',
      name: 'Paper',
      tintColor: 0xFF123456,
      tintIntensity: 0.23,
      noiseIntensity: 0.31,
      grainScale: 1.7,
      animateGrain: true,
      grainBlendMode: 2,
    );

    final decoded = FilterPreset.fromJson(
      jsonDecode(jsonEncode(preset.toJson())),
    );
    expect(decoded.toJson(), preset.toJson());
  });

  test(
    'loads valid custom records when another stored record is malformed',
    () async {
      SharedPreferences.setMockInitialValues({
        SettingsProvider.customPresetsKey: jsonEncode([
          const FilterPreset(
            id: 'good',
            name: 'Good preset',
            tintColor: 0xFFFFAA00,
            tintIntensity: 0.2,
            noiseIntensity: 0.1,
            grainScale: 1,
            animateGrain: false,
            grainBlendMode: 0,
          ).toJson(),
          {'id': 'broken', 'name': 'Broken'},
        ]),
      });
      final provider = SettingsProvider(await SharedPreferences.getInstance());

      expect(provider.customPresets.map((preset) => preset.name), [
        'Good preset',
      ]);
      provider.dispose();
    },
  );

  test(
    'applying a preset persists every setting and syncs active overlay once',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);
      var activeChecks = 0;
      var overlayMessages = 0;
      const methodChannel = MethodChannel('x-slayer/overlay_channel');
      const messageChannel = BasicMessageChannel<dynamic>(
        'x-slayer/overlay_messenger',
        JSONMessageCodec(),
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
            if (call.method == 'isOverlayActive') {
              activeChecks++;
              return true;
            }
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(messageChannel.name, (message) async {
            overlayMessages++;
            return null;
          });

      const preset = FilterPreset(
        id: 'test',
        name: 'Test',
        tintColor: 0xFFABCDEF,
        tintIntensity: 0.42,
        noiseIntensity: 0.35,
        grainScale: 2.2,
        animateGrain: true,
        grainBlendMode: 3,
      );
      await provider.applyPreset(preset);

      expect(prefs.getInt('tint_color'), 0xFFABCDEF);
      expect(prefs.getDouble('tint_intensity'), 0.42);
      expect(prefs.getDouble('noise_intensity'), 0.35);
      expect(prefs.getDouble('grain_scale'), 2.2);
      expect(prefs.getBool('animate_grain'), isTrue);
      expect(prefs.getInt('grain_blend'), 3);
      expect(provider.toOverlayPayload(), {
        'tintColor': 0xFFABCDEF,
        'tintIntensity': 0.42,
        'noiseIntensity': 0.35,
        'grainScale': 2.2,
        'animateGrain': true,
        'grainBlend': 3,
      });
      expect(activeChecks, 1);
      expect(overlayMessages, 1);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(messageChannel.name, null);
      provider.dispose();
    },
  );

  test(
    'custom presets save, survive reload, rename, update and delete',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);
      final saved = await provider.saveCurrentAsPreset('  Reading  ');

      expect(saved?.name, 'Reading');
      expect(await provider.saveCurrentAsPreset('reading'), isNull);
      final reloaded = SettingsProvider(prefs);
      expect(reloaded.customPresets.single.name, 'Reading');

      await prefs.setDouble('tint_intensity', 0.6);
      await reloaded.updatePreset(saved!.id);
      expect(reloaded.customPresets.single.tintIntensity, 0.6);
      expect(await reloaded.renamePreset(saved.id, 'New name'), isTrue);
      expect(await reloaded.renamePreset(saved.id, '  '), isFalse);
      expect(await reloaded.deletePreset(saved.id), isTrue);
      expect(reloaded.customPresets, isEmpty);

      expect(
        await reloaded.updatePreset(FilterPreset.builtIns.first.id),
        isFalse,
      );
      expect(
        await reloaded.renamePreset(FilterPreset.builtIns.first.id, 'Changed'),
        isFalse,
      );
      expect(
        await reloaded.deletePreset(FilterPreset.builtIns.first.id),
        isFalse,
      );
      provider.dispose();
      reloaded.dispose();
    },
  );

  test('built-in preset values remain unchanged', () {
    expect(FilterPreset.builtIns.map((preset) => preset.name), [
      '90s Cel Anime',
      'Warm Manga',
      'VHS Retro',
      'OLED Night',
      'Sunset Lo-Fi',
    ]);
    expect(FilterPreset.builtIns.map((preset) => preset.tintColor), [
      const Color(0xFFFFCA28).toARGB32(),
      const Color(0xFFFFB74D).toARGB32(),
      const Color(0xFF4DD0E1).toARGB32(),
      const Color(0xFF121212).toARGB32(),
      const Color(0xFFFF7043).toARGB32(),
    ]);
    expect(FilterPreset.builtIns.map((preset) => preset.tintIntensity), [
      0.12,
      0.22,
      0.10,
      0.45,
      0.18,
    ]);
    expect(FilterPreset.builtIns.map((preset) => preset.noiseIntensity), [
      0.14,
      0.08,
      0.22,
      0.04,
      0.12,
    ]);
    expect(FilterPreset.builtIns.map((preset) => preset.grainScale), [
      1.2,
      0.8,
      1.8,
      1.0,
      1.1,
    ]);
  });
}
