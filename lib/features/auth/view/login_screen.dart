import 'package:batti_nala/core/utils/validators.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/utils/colors.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/core/models/user_model.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/auth/view/input_label_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Handle login logic
  Future<void> _handleLogin() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    if (_formKey.currentState?.validate() ?? false) {
      final authState = ref.read(authNotifierProvider);

      try {
        await authNotifier.login(authState.email ?? '', authState.password);
      } catch (e) {
        print('[LOGIN_SCREEN] Login error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen for user changes only (not entire state which fires repeatedly)
    ref.listen<User?>(authNotifierProvider.select((state) => state.user), (
      previous,
      next,
    ) {
      // Only navigate if user just logged in (transitioned from null to logged in)
      if (next != null && previous == null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final role = next.role;
            final route = role == 'citizen'
                ? '/citizen-dashboard'
                : '/staff-dashboard';
            context.go(route);
          }
        });
      }
    });

    // Listen for error messages
    ref.listen<String?>(
      authNotifierProvider.select((state) => state.errorMessage),
      (previous, next) {
        if (next != null && next.isNotEmpty && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              SnackbarService.showError(context, next);
              ref.read(authNotifierProvider.notifier).clearError();
            }
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const AuthHeaderWidget(
                  mainText: 'Welcome Back',
                  infoText: 'Sign in to continue',
                ),
                const SizedBox(height: 30),

                // Email/Phone34 Field
                InputLabelWidget(
                  validator: AppValidators.validateUsername,
                  icon: FontAwesomeIcons.envelope,
                  inputType: TextInputType.emailAddress,
                  label: 'Email/Phone',
                  hint: 'Enter your email or phone number',
                  onChanged: (val) =>
                      ref.read(authNotifierProvider.notifier).updateEmail(val),
                ),

                const SizedBox(height: 20),

                // Password Field
                InputLabelWidget(
                  validator: AppValidators.validatePassword,
                  icon: FontAwesomeIcons.lock,
                  inputType: TextInputType.visiblePassword,
                  isPassword: true,
                  label: 'Password',
                  hint: 'Enter your password',
                  onChanged: (val) => ref
                      .read(authNotifierProvider.notifier)
                      .updatePassword(val),
                ),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      context.push('/password-reset');
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Login Button
                ActionButton(
                  width: double.infinity,
                  label: authState.isLoading ? 'Signing In...' : 'Sign In',
                  backgroundColor: AppColors.primaryBlue,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _handleLogin();
                    }
                  },
                  isLoading: authState.isLoading,
                ),

                _buildRegisterLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: GestureDetector(
          onTap: () {
            // Optional: Reset form when navigating
            ref.read(authNotifierProvider.notifier).resetForm();
            context.push('/signup');
          },
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
              children: [
                TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const TextSpan(
                  text: 'Register',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
