import 'package:batti_nala/features/auth/view/login_screen.dart';
import 'package:batti_nala/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
