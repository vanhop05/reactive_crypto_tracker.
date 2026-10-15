import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'views/main_navigation_screen.dart';

void main() {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI overlay style for dark fintech aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF151B26),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Demonstrate Event Loop startup logging
  scheduleMicrotask(() {
    debugPrint('[EVENT_LOOP] Microtask executed during application bootstrap.');
  });

  runApp(const CryptoPulseApp());
}

/// Root widget of the CryptoPulse Reactive application.
class CryptoPulseApp extends StatelessWidget {
  const CryptoPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CryptoPulse Reactive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to sleek dark theme
      home: const MainNavigationScreen(),
    );
  }
}
