import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    loadOnboardingStatus();
  }

  /// Get the onboarding status from local storage
  Future<void> loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state =
        prefs.getBool('hasSeenOnboarding') ??
        false; // false if not set or key doesn't exist
  }

  /// Set the onboarding status in local storage
  Future<void> completeOnBoarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    state = true;
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>(
  (ref) => OnboardingNotifier(),
);
