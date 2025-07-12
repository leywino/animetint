import 'dart:developer';
import 'package:animetint/components/overlay.dart';
import 'package:animetint/pages/home_screen.dart';
import 'package:animetint/controller/settings_provider.dart';
import 'package:animetint/pages/permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final firstLaunchCompleted = prefs.getBool("first_launch_completed") ?? false;

  runApp(MyApp(prefs: prefs, firstLaunchCompleted: firstLaunchCompleted));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final bool firstLaunchCompleted;

  const MyApp({
    super.key,
    required this.prefs,
    required this.firstLaunchCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(prefs),
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.values[settingsProvider.theme.index],
            darkTheme: ThemeData.dark(useMaterial3: true),
            theme: ThemeData.light(useMaterial3: true),
            home:
                firstLaunchCompleted
                    ? const HomeScreen()
                    : const PermissionScreen(),
          );
        },
      ),
    );
  }
}

@pragma("vm:entry-point")
void overlayMain() async {
  log("✅ Overlay Entry Point Reached");

  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(prefs),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: OverlayScreen(),
      ),
    ),
  );
}
