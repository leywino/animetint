import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:animetint/components/film_grain_painter.dart';
import 'package:animetint/controller/settings_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Listen to live updates sent from the main app isolate
    _subscription = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is String && mounted) {
        try {
          final Map<String, dynamic> data = jsonDecode(event);
          context.read<SettingsProvider>().applyFromPayload(data);
        } catch (e) {
          log("Overlay sync parse error: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base Color Tint Layer
            Container(
              color: settings.tintColor.withValues(
                alpha: settings.tintIntensity,
              ),
            ),

            // Procedural Film Grain Layer
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
}