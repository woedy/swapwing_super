import 'package:flutter/material.dart';
import 'package:swapwing/theme.dart';
import 'package:swapwing/screens/splash_screen.dart';

void main() {
  runApp(const SwapWingApp());
}

class SwapWingApp extends StatelessWidget {
  const SwapWingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwapWing - Trade Smart, Trade Up',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
