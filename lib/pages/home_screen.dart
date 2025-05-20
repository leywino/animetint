import 'dart:io';

import 'package:anime_tint/controller/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _overlayGranted = false;
  bool _batteryGranted = false;
  bool _settingsChanged = false;
  bool _isOverlayActive = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchOverlayStatus();
  }

  Future<void> _checkPermissions() async {
    _overlayGranted = await Permission.systemAlertWindow.isGranted;
    _batteryGranted = await Permission.ignoreBatteryOptimizations.isGranted;
    setState(() {});
  }

  Future<void> _fetchOverlayStatus() async {
    bool isActive = await FlutterOverlayWindow.isActive();
    setState(() => _isOverlayActive = isActive);
  }

  Future<void> _requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    setState(() => _overlayGranted = status.isGranted);
  }

  Future<void> _requestBatteryPermission() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    setState(() => _batteryGranted = status.isGranted);
  }

  Future<void> _toggleOverlay(bool isEnabled) async {
    if (isEnabled) {
      await FlutterOverlayWindow.showOverlay(
        height: 3000,
        width: WindowSize.fullCover,
        flag: OverlayFlag.clickThrough,
        overlayTitle: "AnimeTint",
        overlayContent: "Overlay Running...",
        enableDrag: false,
        visibility: NotificationVisibility.visibilityPublic,
        alignment: OverlayAlignment.bottomCenter,
      );
    } else {
      await FlutterOverlayWindow.closeOverlay();
    }
    setState(() => _isOverlayActive = isEnabled);
  }

  void _restartApp(SettingsProvider settingsProvider) async {
    _toggleOverlay(false);
    await Future.delayed(Duration(milliseconds: 500));
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("AnimeTint"),
            actions: [
              Switch(
                value: _isOverlayActive,
                onChanged: (value) => _toggleOverlay(value),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle("Appearance", Theme.of(context)),
              _buildTintColorPicker(settingsProvider),
              _buildTintIntensitySlider(settingsProvider),
              _buildNoiseIntensitySlider(settingsProvider),

              const SizedBox(height: 20),

              _buildSectionTitle("Permissions", Theme.of(context)),
              _buildPermissionSettings(),

              // Restart App Button if settings are changed
              if (_settingsChanged)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      _restartApp(settingsProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Restart App to Apply Settings"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTintColorPicker(SettingsProvider settingsProvider) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text("Tint Color"),
      subtitle: const Text("Tap to change the tint color"),
      trailing: CircleAvatar(
        backgroundColor: settingsProvider.tintColor,
        radius: 16,
      ),
      onTap: () async {
        Color? pickedColor = await showDialog<Color>(
          context: context,
          builder:
              (context) =>
                  _ColorPickerDialog(initialColor: settingsProvider.tintColor),
        );
        if (pickedColor != null) {
          settingsProvider.tintColor = pickedColor;
          setState(() => _settingsChanged = true); // Show Restart Button
        }
      },
    );
  }

  Widget _buildTintIntensitySlider(SettingsProvider settingsProvider) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Tint Intensity"),
          subtitle: Text("${(settingsProvider.tintIntensity * 100).toInt()}%"),
        ),
        Slider(
          value: settingsProvider.tintIntensity,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: "${(settingsProvider.tintIntensity * 100).toInt()}%",
          onChanged: (value) {
            settingsProvider.tintIntensity = value;
            setState(() => _settingsChanged = true);
          },
        ),
      ],
    );
  }

  Widget _buildNoiseIntensitySlider(SettingsProvider settingsProvider) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Noise Intensity"),
          subtitle: Text("${(settingsProvider.noiseIntensity * 100).toInt()}%"),
        ),
        Slider(
          value: settingsProvider.noiseIntensity,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: "${(settingsProvider.noiseIntensity * 100).toInt()}%",
          onChanged: (value) {
            settingsProvider.noiseIntensity = value;
            setState(() => _settingsChanged = true);
          },
        ),
      ],
    );
  }

  Widget _buildPermissionSettings() {
    return Column(
      children: [
        // Overlay Permission
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Overlay Permission"),
          subtitle: const Text("Required for screen tinting over other apps."),
          trailing:
              _overlayGranted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                    onPressed: _requestOverlayPermission,
                    child: const Text("Grant"),
                  ),
        ),

        const SizedBox(height: 10),

        // Battery Optimization Permission
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Battery Optimization"),
          subtitle: const Text(
            "Recommended to prevent background interruptions.",
          ),
          trailing:
              _batteryGranted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : ElevatedButton(
                    onPressed: _requestBatteryPermission,
                    child: const Text("Grant"),
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

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Tint Color"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildColorOption(Colors.yellow),
            _buildColorOption(Colors.amber),
            _buildColorOption(Colors.orange),
            _buildColorOption(Colors.red),
            _buildColorOption(Colors.blue),
            _buildColorOption(Colors.green),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: const Text("Select"),
        ),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: double.infinity,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
