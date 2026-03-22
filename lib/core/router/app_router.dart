import 'package:batti_nala/features/citizen_dashboard/view/issue_create_view.dart';
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
import 'package:batti_nala/features/auth/view/password_reset_screen.dart';
import 'package:batti_nala/features/citizen_dashboard/view/issue_detail_view.dart';

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
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
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
      GoRoute(
        path: '/issue-create',
        builder: (context, state) => const ReportIssueScreen(),
      ),
      GoRoute(
        path: '/issue-detail/:label',
        builder: (context, state) {
          final label = state.pathParameters['label']!;
          return IssueDetailView(issueLabel: label);
        },
      ),
    ],
    redirect: (context, state) {
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/password-reset';
      final isProfileRoute = state.matchedLocation == '/profile';

      // Logged-in user shouldn't see onboarding or auth screens
      if (user != null && isOnOnboarding) {
        return user.role == 'citizen' ? '/citizen-dashboard' : '/staff-dashboard';
      }

      // Allow profile route only if logged in
      if (isProfileRoute) {
        return user == null ? '/login' : null;
      }

      // If not logged in, allow auth routes and onboarding
      if (user == null) {
        final shouldAllow = isAuthRoute || isOnOnboarding;
        // Redirect to login (not onboarding) after logout
        return shouldAllow ? null : '/login';
      }

      // If logged in but trying to access auth routes, redirect to dashboard
      if (isAuthRoute) {
        return user.role == 'citizen' ? '/citizen-dashboard' : '/staff-dashboard';
      }

      return null;
    },
  );
});
