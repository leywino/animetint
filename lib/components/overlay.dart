import 'dart:developer';
import 'package:animetint/controller/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    log("✅ Overlay UI Loaded");

    final settingsProvider = Provider.of<SettingsProvider>(context);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen Tint Layer
          Positioned.fill(
            child: Container(
              height: double.infinity,
              width: double.infinity,
              color: settingsProvider.tintColor.withValues(
                alpha: settingsProvider.tintIntensity,
              ),
            ),
          ),

          // Noise/Grain Texture Layer
          Positioned.fill(
            child: Opacity(
              opacity: settingsProvider.noiseIntensity,
              child: Image.asset(
                "assets/noise.png",
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
