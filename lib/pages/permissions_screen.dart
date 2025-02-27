import 'package:anime_tint/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _overlayGranted = false;
  bool _batteryGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// **Check current permissions**
  Future<void> _checkPermissions() async {
    _overlayGranted = await Permission.systemAlertWindow.isGranted;
    _batteryGranted = await Permission.ignoreBatteryOptimizations.isGranted;
    setState(() {});
  }

  /// **Request Overlay Permission (Mandatory)**
  Future<void> _requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    if (status.isGranted) {
      setState(() => _overlayGranted = true);
    } else if (status.isPermanentlyDenied) {
      _openAppSettingsDialog("Overlay Permission");
    }
  }

  /// **Request Battery Optimization Permission (Optional)**
  Future<void> _requestBatteryPermission() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (status.isGranted) {
      setState(() => _batteryGranted = true);
    } else if (status.isPermanentlyDenied) {
      _openAppSettingsDialog("Battery Optimization");
    }
  }

  /// **Dialog to open app settings for permanently denied permissions**
  void _openAppSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$permissionName Required"),
        content: Text(
          "To enable $permissionName, please open settings and grant the required permission.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  /// **Save first launch & navigate to home screen**
  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("first_launch_completed", true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMandatoryGranted = _overlayGranted;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.settings_rounded,
                size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              "Permissions Required",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "To use this app properly, please allow the following permissions.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),

            // Required Permissions Section
            _buildPermissionCard(
              title: "Required",
              permissions: [
                _buildPermissionTile(
                  "Overlay Permission",
                  "Allows the app to show overlays on top of other apps.",
                  _overlayGranted,
                  _requestOverlayPermission,
                ),
              ],
            ),

            // Optional Permissions Section
            _buildPermissionCard(
              title: "Optional",
              permissions: [
                _buildPermissionTile(
                  "Battery Optimization",
                  "Allows the app to run in the background without interruptions.",
                  _batteryGranted,
                  _requestBatteryPermission,
                ),
              ],
            ),

            const Spacer(),

            // Get Started Button (only enabled when mandatory permissions are granted)
            ElevatedButton(
              onPressed: isMandatoryGranted ? _completeSetup : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }

  /// **Build Permission Card**
  Widget _buildPermissionCard({
    required String title,
    required List<Widget> permissions,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...permissions,
          ],
        ),
      ),
    );
  }

  /// **Build Permission Tile**
  Widget _buildPermissionTile(
      String title, String description, bool isGranted, VoidCallback onPressed) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: ElevatedButton(
        onPressed: isGranted ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(isGranted ? "Granted" : "Grant"),
      ),
    );
  }
}
