import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/view/login_screen.dart';
import 'package:batti_nala/features/auth/view/signup_screen.dart';
import 'package:batti_nala/features/profile/view/profile_screen.dart';
import 'package:batti_nala/features/onboarding/onboarding_screen.dart';
import 'package:batti_nala/features/citizen_dashboard/view/citizen_dashboard_view.dart';
import 'package:batti_nala/features/staff_dashboard/view/dashboard_screen.dart';
import 'package:batti_nala/features/staff_dashboard/model/staff_model.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authNotifierProvider.select((state) => state.user));

  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/citizen-dashboard',
        builder: (context, state) => const CitizenDashboardView(),
      ),
      GoRoute(
        path: '/staff-dashboard',
        builder: (context, state) => StaffDashboard(
          staff: Staff(
            name: 'Staff Member',
            department: 'Management',
            avatar: '',
          ),
          onViewMap: () {},
          onViewIssue: (issue) {},
          onNavigateToProfile: () => context.push('/profile'),
        ),
      ),
    ],
    redirect: (context, state) {
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isProfileRoute = state.matchedLocation == '/profile';

      // If user is logged in, don't show onboarding
      if (user != null && isOnOnboarding) {
        if (user.role == 'citizen') {
          return '/citizen-dashboard';
        } else if (user.role == 'staff') {
          return '/staff-dashboard';
        }
      }

      // Allow profile route only if logged in
      if (isProfileRoute) {
        if (user == null) {
          return '/onboarding';
        }
        return null;
      }

      // If not logged in, allow login/signup/onboarding
      if (user == null) {
        final shouldAllow = isAuthRoute || isOnOnboarding;
        return shouldAllow ? null : '/onboarding';
      }

      // If logged in but on auth routes, redirect to dashboard
      if (isAuthRoute) {
        if (user.role == 'citizen') {
          return '/citizen-dashboard';
        } else if (user.role == 'staff') {
          return '/staff-dashboard';
        }
      }

      return null;
    },
  );
});
