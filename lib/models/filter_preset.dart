import 'package:material_ui/material_ui.dart';

/// A complete set of AnimeTint filter settings.
class FilterPreset {
  const FilterPreset({
    required this.id,
    required this.name,
    required this.tintColor,
    required this.tintIntensity,
    required this.noiseIntensity,
    required this.grainScale,
    required this.animateGrain,
    required this.grainBlendMode,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final int tintColor;
  final double tintIntensity;
  final double noiseIntensity;
  final double grainScale;
  final bool animateGrain;
  final int grainBlendMode;
  final bool isBuiltIn;

  Color get color => Color(tintColor);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tintColor': tintColor,
    'tintIntensity': tintIntensity,
    'noiseIntensity': noiseIntensity,
    'grainScale': grainScale,
    'animateGrain': animateGrain,
    'grainBlendMode': grainBlendMode,
  };

  factory FilterPreset.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final color = json['tintColor'];
    final tint = json['tintIntensity'];
    final noise = json['noiseIntensity'];
    final scale = json['grainScale'];
    final animate = json['animateGrain'];
    final blend = json['grainBlendMode'];

    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        color is! int ||
        color < 0 ||
        color > 0xFFFFFFFF ||
        tint is! num ||
        !tint.toDouble().isFinite ||
        tint < 0 ||
        tint > 0.85 ||
        noise is! num ||
        !noise.toDouble().isFinite ||
        noise < 0 ||
        noise > 0.60 ||
        scale is! num ||
        !scale.toDouble().isFinite ||
        scale < 0.5 ||
        scale > 3.0 ||
        animate is! bool ||
        blend is! int ||
        blend < 0 ||
        blend >= 4) {
      throw const FormatException('Invalid filter preset');
    }

    return FilterPreset(
      id: id,
      name: name.trim(),
      tintColor: color,
      tintIntensity: tint.toDouble(),
      noiseIntensity: noise.toDouble(),
      grainScale: scale.toDouble(),
      animateGrain: animate,
      grainBlendMode: blend,
    );
  }

  FilterPreset copyWith({String? id, String? name}) => FilterPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    tintColor: tintColor,
    tintIntensity: tintIntensity,
    noiseIntensity: noiseIntensity,
    grainScale: grainScale,
    animateGrain: animateGrain,
    grainBlendMode: grainBlendMode,
    isBuiltIn: isBuiltIn,
  );

  static const builtIns = <FilterPreset>[
    FilterPreset(
      id: 'builtin-90s-cel-anime',
      name: '90s Cel Anime',
      tintColor: 0xFFFFCA28,
      tintIntensity: 0.12,
      noiseIntensity: 0.14,
      grainScale: 1.2,
      animateGrain: false,
      grainBlendMode: 0,
      isBuiltIn: true,
    ),
    FilterPreset(
      id: 'builtin-warm-manga',
      name: 'Warm Manga',
      tintColor: 0xFFFFB74D,
      tintIntensity: 0.22,
      noiseIntensity: 0.08,
      grainScale: 0.8,
      animateGrain: false,
      grainBlendMode: 0,
      isBuiltIn: true,
    ),
    FilterPreset(
      id: 'builtin-vhs-retro',
      name: 'VHS Retro',
      tintColor: 0xFF4DD0E1,
      tintIntensity: 0.10,
      noiseIntensity: 0.22,
      grainScale: 1.8,
      animateGrain: false,
      grainBlendMode: 0,
      isBuiltIn: true,
    ),
    FilterPreset(
      id: 'builtin-oled-night',
      name: 'OLED Night',
      tintColor: 0xFF121212,
      tintIntensity: 0.45,
      noiseIntensity: 0.04,
      grainScale: 1.0,
      animateGrain: false,
      grainBlendMode: 0,
      isBuiltIn: true,
    ),
    FilterPreset(
      id: 'builtin-sunset-lo-fi',
      name: 'Sunset Lo-Fi',
      tintColor: 0xFFFF7043,
      tintIntensity: 0.18,
      noiseIntensity: 0.12,
      grainScale: 1.1,
      animateGrain: false,
      grainBlendMode: 0,
      isBuiltIn: true,
    ),
  ];
}
