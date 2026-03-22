import 'package:batti_nala/core/utils/validators.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/core/models/user_model.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/auth/view/input_label_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _keyForm = GlobalKey<FormState>();

  // Handle signup logic
  Future<void> _handleSignUp() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    if (_keyForm.currentState?.validate() ?? false) {
      final authState = ref.read(authNotifierProvider);
      try {
        await authNotifier.register(
          username: authState.name,
          password: authState.password,
          name: authState.name,
          phoneNumber: authState.phone,
          email: authState.email ?? '',
          homeAddress: authState.homeAddress,
        );
      } catch (_) {
        // Error is shown via snackbar through the state listener
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
      // Only navigate if user just signed up (transitioned from null to logged in)
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
            key: _keyForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const AuthHeaderWidget(
                  mainText: 'Create Account',
                  infoText: 'Sign up to get started',
                ),
                const SizedBox(height: 30),

                // Name Field
                InputLabelWidget(
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.validateName,
                  icon: FontAwesomeIcons.user,
                  inputType: TextInputType.name,
                  label: 'Full Name*',
                  hint: 'Enter your name',
                  onChanged: (val) =>
                      ref.read(authNotifierProvider.notifier).updateName(val),
                ),

                const SizedBox(height: 20),

                // Phone Field
                InputLabelWidget(
                  validator: AppValidators.validatePhone,
                  icon: FontAwesomeIcons.phone,
                  inputType: TextInputType.phone,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  onChanged: (val) =>
                      ref.read(authNotifierProvider.notifier).updatePhone(val),
                ),

                const SizedBox(height: 20),

                // Email Field
                InputLabelWidget(
                  validator: AppValidators.validateEmail,
                  icon: FontAwesomeIcons.envelope,
                  inputType: TextInputType.emailAddress,
                  label: 'Email Address*',
                  hint: 'Enter your email',
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
                  label: 'Password*',
                  hint: 'Enter your password',
                  onChanged: (val) => ref
                      .read(authNotifierProvider.notifier)
                      .updatePassword(val),
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                InputLabelWidget(
                  validator: (value) => AppValidators.validateConfirmPassword(
                    value,
                    ref.read(authNotifierProvider).password,
                  ),
                  icon: FontAwesomeIcons.lock,
                  inputType: TextInputType.visiblePassword,
                  isPassword: true,
                  label: 'Confirm Password*',
                  hint: 'Confirm your password',
                  onChanged: (val) => ref
                      .read(authNotifierProvider.notifier)
                      .updateConfirmPassword(val),
                ),

                const SizedBox(height: 20),

                // Home Address Field (Optional)
                InputLabelWidget(
                  icon: FontAwesomeIcons.locationDot,
                  inputType: TextInputType.streetAddress,
                  label: 'Home Address (Optional)',
                  hint: 'e.g. Kathmandu, Ward 10',
                  textCapitalization: TextCapitalization.words,
                  onChanged: (val) => ref
                      .read(authNotifierProvider.notifier)
                      .updateHomeAddress(val),
                ),

                const SizedBox(height: 20),

                // Signup Button
                ActionButton(
                  width: double.infinity,
                  label: authState.isLoading
                      ? 'Creating Account...'
                      : 'Sign Up',
                  backgroundColor: AppColors.primaryBlue,
                  onPressed: () {
                    if (_keyForm.currentState!.validate()) {
                      _handleSignUp();
                    }
                  },
                ),

                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        child: GestureDetector(
          onTap: () {
            ref.read(authNotifierProvider.notifier).resetForm();
            context.pop();
          },
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
              children: [
                TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const TextSpan(
                  text: 'Login',
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
