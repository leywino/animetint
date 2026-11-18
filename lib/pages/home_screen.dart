import 'dart:convert';
import 'package:animetint/components/film_grain_painter.dart';
import 'package:animetint/controller/settings_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isOverlayActive = false;

  @override
  void initState() {
    super.initState();
    _fetchOverlayStatus();
  }

  Future<void> _fetchOverlayStatus() async {
    bool isActive = await FlutterOverlayWindow.isActive();
    if (mounted) setState(() => _isOverlayActive = isActive);
  }

  Future<void> _toggleOverlay(bool isEnabled, SettingsProvider provider) async {
    if (isEnabled) {
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        flag: OverlayFlag.clickThrough,
        overlayTitle: "AnimeTint",
        overlayContent: "Screen filter active",
        enableDrag: false,
        visibility: NotificationVisibility.visibilityPublic,
      );
      // Push latest state immediately after window spawns
      await Future.delayed(const Duration(milliseconds: 250));
      await FlutterOverlayWindow.shareData(
        jsonEncode(provider.toOverlayPayload()),
      );
    } else {
      await FlutterOverlayWindow.closeOverlay();
    }
    if (mounted) setState(() => _isOverlayActive = isEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AnimeTint",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Reset to defaults",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              settings.resetSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Settings reset to default"),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Switch(
              value: _isOverlayActive,
              onChanged: (val) => _toggleOverlay(val, settings),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 1. Live Interactive Preview Card
          _buildLivePreviewCard(settings),
          const SizedBox(height: 20),

          // 2. Curated Presets
          _buildSectionHeader("Presets"),
          const SizedBox(height: 8),
          _buildPresetsRow(settings),
          const SizedBox(height: 24),

          // 3. Color Grading Controls
          _buildSectionHeader("Color Grading"),
          const SizedBox(height: 8),
          _buildCard(
            colorScheme,
            children: [
              _buildTintColorPicker(settings),
              const Divider(height: 28),
              _buildPrecisionSlider(
                label: "Tint Opacity",
                value: settings.tintIntensity,
                min: 0.0,
                max: 0.85,
                displayValue: "${(settings.tintIntensity * 100).round()}%",
                onChanged: (v) => settings.tintIntensity = v,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Film Grain & Texture Engine
          _buildSectionHeader("Film Grain Engine"),
          const SizedBox(height: 8),
          _buildCard(
            colorScheme,
            children: [
              _buildPrecisionSlider(
                label: "Grain Strength",
                value: settings.noiseIntensity,
                min: 0.0,
                max: 0.60,
                displayValue: "${(settings.noiseIntensity * 100).round()}%",
                onChanged: (v) => settings.noiseIntensity = v,
              ),
              const Divider(height: 24),
              _buildPrecisionSlider(
                label: "Grain Size",
                value: settings.grainScale,
                min: 0.5,
                max: 3.0,
                step: 0.1,
                displayValue: "${settings.grainScale.toStringAsFixed(1)}x",
                onChanged: (v) => settings.grainScale = v,
              ),
              const Divider(height: 24),
              _buildBlendModeSelector(settings),
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "24fps Film Jitter",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Subtle analog celluloid grain motion"),
                value: settings.animateGrain,
                onChanged: (v) => settings.animateGrain = v,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(SettingsProvider settings) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 150,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Sample gradient backdrop to inspect grain & tint clarity
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A237E),
                    Color(0xFF880E4F),
                    Color(0xFFFF8F00),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "LIVE FILTER PREVIEW",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "90s Cel Anime • Grain & Color Grade",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            // Tint Layer
            Container(
              color: settings.tintColor.withValues(alpha: settings.tintIntensity),
            ),
            // Grain Layer
            ProceduralFilmGrain(
              intensity: settings.noiseIntensity,
              scale: settings.grainScale,
              animate: settings.animateGrain,
              blendMode: settings.grainBlendMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ColorScheme scheme, {required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPresetsRow(SettingsProvider provider) {
    final presets = [
      {
        "name": "90s Cel Anime",
        "color": const Color(0xFFFFCA28),
        "tint": 0.12,
        "noise": 0.14,
        "scale": 1.2,
      },
      {
        "name": "Warm Manga",
        "color": const Color(0xFFFFB74D),
        "tint": 0.22,
        "noise": 0.08,
        "scale": 0.8,
      },
      {
        "name": "VHS Retro",
        "color": const Color(0xFF4DD0E1),
        "tint": 0.10,
        "noise": 0.22,
        "scale": 1.8,
      },
      {
        "name": "OLED Night",
        "color": const Color(0xFF121212),
        "tint": 0.45,
        "noise": 0.04,
        "scale": 1.0,
      },
      {
        "name": "Sunset Lo-Fi",
        "color": const Color(0xFFFF7043),
        "tint": 0.18,
        "noise": 0.12,
        "scale": 1.1,
      },
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final p = presets[index];
          final color = p['color'] as Color;
          return ActionChip(
            avatar: CircleAvatar(backgroundColor: color, radius: 10),
            label: Text(p['name'] as String),
            onPressed: () {
              provider.tintColor = color;
              provider.tintIntensity = p['tint'] as double;
              provider.noiseIntensity = p['noise'] as double;
              provider.grainScale = p['scale'] as double;
            },
          );
        },
      ),
    );
  }

  Widget _buildTintColorPicker(SettingsProvider settings) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        "Tint Color",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text("Tap to pick custom color wash"),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: settings.tintColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 2),
        ),
      ),
      onTap: () async {
        Color? picked = await showDialog<Color>(
          context: context,
          builder: (_) => _ColorPickerDialog(initialColor: settings.tintColor),
        );
        if (picked != null) settings.tintColor = picked;
      },
    );
  }

  Widget _buildPrecisionSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    double step = 0.01,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    final clamped = value.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: clamped > min
                  ? () => onChanged((clamped - step).clamp(min, max))
                  : null,
            ),
            Expanded(
              child: Slider(
                value: clamped,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: clamped < max
                  ? () => onChanged((clamped + step).clamp(min, max))
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlendModeSelector(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Grain Blend Style",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<GrainBlendMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: GrainBlendMode.softLight,
                label: Text("Soft", style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: GrainBlendMode.overlay,
                label: Text("Contrast", style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: GrainBlendMode.multiply,
                label: Text("Dark", style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: GrainBlendMode.screen,
                label: Text("Light", style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {settings.grainBlendMode},
            onSelectionChanged: (set) => settings.grainBlendMode = set.first,
          ),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color selectedColor;

  final List<Color> colorOptions = const [
    Color(0xFFFFE082),
    Color(0xFFFFB74D),
    Color(0xFFFF7043),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFF4DD0E1),
    Color(0xFF66BB6A),
    Color(0xFFD7CCC8),
    Color(0xFF121212),
  ];

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Tint Color"),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: colorOptions.map((color) {
          final isSelected = selectedColor.toARGB32() == color.toARGB32();
          return GestureDetector(
            onTap: () => setState(() => selectedColor = color),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.withValues(alpha: 0.4),
                  width: isSelected ? 3.5 : 1.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: const Text("Apply"),
        ),
      ],
    );
  }
}