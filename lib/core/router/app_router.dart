import 'package:batti_nala/features/auth/view/verify_otp_screen.dart';
import 'package:batti_nala/features/user-issue/view/issue_create_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/view/login_screen.dart';
import 'package:batti_nala/features/auth/view/signup_screen.dart';
import 'package:batti_nala/features/profile/view/profile_screen.dart';
import 'package:batti_nala/features/onboarding/onboarding_screen.dart';
import 'package:batti_nala/features/citizen_dashboard/view/citizen_dashboard_view.dart';
import 'package:batti_nala/features/staff_dashboard/view/dashboard_screen.dart';
import 'package:batti_nala/features/auth/view/password_reset_screen.dart';
import 'package:batti_nala/features/user-issue/view/issue_detail_view.dart';
import 'package:batti_nala/features/staff-issue/view/employee_issue_detail_view.dart';
import 'package:batti_nala/features/shared-issue/models/issue_model.dart';
import 'package:batti_nala/features/staff_dashboard/view/mission_map_view.dart';

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
        path: '/verify-otp',
        builder: (context, state) => const VerifyOtpScreen(),
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
        builder: (context, state) => const StaffDashboard(),
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
      GoRoute(
        path: '/employee-issue-detail/:label',
        builder: (context, state) {
          final label = state.pathParameters['label']!;
          return EmployeeIssueDetailView(issueLabel: label);
        },
      ),
      GoRoute(
        path: '/mission-map',
        name: 'mission-map',
        builder: (context, state) {
          final issue = state.extra as IssueModel;
          return MissionMapView(issue: issue);
        },
      ),
    ],
    redirect: (context, state) {
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/password-reset';
      final isOnVerifyScreen = state.matchedLocation == '/verify-otp';

      // 1. If not logged in
      if (user == null) {
        // Only allow auth routes and onboarding
        final isAllowed = isAuthRoute || isOnOnboarding;
        return isAllowed ? null : '/login';
      }

      // 2. If logged in but NOT verified
      if (!user.isVerified) {
        // Only allow the verification screen
        return isOnVerifyScreen ? null : '/verify-otp';
      }

      // 3. If logged in AND verified
      // Don't allow auth screens, onboarding, or verify screen
      if (isAuthRoute || isOnOnboarding || isOnVerifyScreen) {
        return user.role == 'citizen'
            ? '/citizen-dashboard'
            : '/staff-dashboard';
      }

      // Allow all other routes (dashboard, profile, etc.)
      return null;
    },
  );
});
