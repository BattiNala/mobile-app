import 'package:batti_nala/core/utils/validators.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/utils/colors.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/auth/view/input_label_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.signup();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen for state changes (errors and success navigation)
    ref.listen(authProvider, (previous, next) {
      final errorMessage = next.errorMessage;
      if (errorMessage != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackbarService.showError(context, errorMessage);
          ref.read(authProvider.notifier).clearError();
        });
      }

      if (next.isLoading == false &&
          next.errorMessage == null &&
          mounted &&
          previous?.isLoading == true) {
        Navigator.pushReplacementNamed(context, '/staff_dashboard');
      }
    });

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
                  mainText: "Create Account",
                  infoText: "Sign up to get started",
                ),
                const SizedBox(height: 30),

                // Name Field
                InputLabelWidget(
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.validateName,
                  icon: FontAwesomeIcons.user,
                  inputType: TextInputType.name,
                  label: 'Full Name',
                  hint: 'Enter your name',
                  onChanged: (val) =>
                      ref.read(authProvider.notifier).updateName(val),
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
                      ref.read(authProvider.notifier).updatePhone(val),
                ),

                const SizedBox(height: 20),

                // Email Field
                InputLabelWidget(
                  validator: AppValidators.validateEmail,
                  icon: FontAwesomeIcons.envelope,
                  inputType: TextInputType.emailAddress,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  onChanged: (val) =>
                      ref.read(authProvider.notifier).updateEmail(val),
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
                  onChanged: (val) =>
                      ref.read(authProvider.notifier).updatePassword(val),
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                InputLabelWidget(
                  validator: (value) => AppValidators.validateConfirmPassword(
                    value,
                    ref.read(authProvider).password,
                  ),
                  icon: FontAwesomeIcons.lock,
                  inputType: TextInputType.visiblePassword,
                  isPassword: true,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  onChanged: (val) => ref
                      .read(authProvider.notifier)
                      .updateConfirmPassword(val),
                ),

                const SizedBox(height: 20),

                // Signup Button
                ActionButton(
                  btnInfo: authState.isLoading
                      ? "Creating Account..."
                      : "Sign Up",
                  btnColor: AppColors.primaryBlue,
                  onTap: () {
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
            ref.read(authProvider.notifier).resetForm();
            Navigator.pop(context);
          },
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
              children: [
                TextSpan(
                  text: "Already have an account? ",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: "Login",
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
