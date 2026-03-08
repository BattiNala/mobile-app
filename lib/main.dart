import 'package:batti_nala/features/auth/view/login_screen.dart';
import 'package:batti_nala/features/auth/view/signup_screen.dart';
import 'package:batti_nala/features/staff_dashboard/model/issue_model.dart';
import 'package:batti_nala/features/staff_dashboard/view/dashboard_screen.dart';
import 'package:batti_nala/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: const MainApp()));
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
        '/signup': (context) => SignupScreen(),
        '/staff_dashboard': (context) => StaffDashboard(
          staff: currentUser,
          onViewMap: () {
            // Navigate to map view
          },
          onViewIssue: (Issue issue) {
            // Navigate to issue details
            print('Viewing issue: ${issue.id}');
          },
          onNavigateToProfile: () {
            // Navigate to profile
          },
        ),
      },
    );
  }
}
