import 'dart:developer';
import 'package:anime_tint/controller/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    log("✅ Overlay UI Loaded");

    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen Tint Layer
          Positioned.fill(
            child: Container(
              color: settingsProvider.tintColor.withValues(
                alpha: settingsProvider.tintIntensity,
              ),
            ),
          ),

          // Noise/Grain Texture Layer
          Positioned.fill(
            child: Opacity(
              opacity: settingsProvider.noiseIntensity,
              child: Image.asset("assets/noise.png", fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}
