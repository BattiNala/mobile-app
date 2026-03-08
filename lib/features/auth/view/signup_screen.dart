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
                  capitalization: TextCapitalization.words,
                  validator: AppValidators.validateName,
                  labelInfo: "Full Name",
                  hintText: "Enter your name",
                  icon: FontAwesomeIcons.user,
                  fieldType: AuthFieldType.email,
                  keyboardType: TextInputType.text,
                ),

                const SizedBox(height: 20),

                // Phone Field
                InputLabelWidget(
                  validator: AppValidators.validatePhone,
                  labelInfo: "Phone Number",
                  hintText: "Enter your phone number",
                  icon: FontAwesomeIcons.phone,
                  fieldType: AuthFieldType.email,
                  keyboardType: TextInputType.numberWithOptions(),
                ),

                const SizedBox(height: 20),

                // Email Field
                InputLabelWidget(
                  validator: AppValidators.validateEmail,
                  labelInfo: "Email Address",
                  hintText: "Enter your email",
                  icon: FontAwesomeIcons.envelope,
                  fieldType: AuthFieldType.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // Password Field
                InputLabelWidget(
                  validator: AppValidators.validatePassword,
                  labelInfo: "Password",
                  hintText: "Enter your password",
                  icon: FontAwesomeIcons.lock,
                  fieldType: AuthFieldType.password,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                InputLabelWidget(
                  validator: (value) => AppValidators.validateConfirmPassword(
                    value,
                    ref.read(authProvider).password,
                  ),
                  labelInfo: "Confirm Password",
                  hintText: "Confirm your password",
                  icon: FontAwesomeIcons.lock,
                  fieldType: AuthFieldType.confirmPassword,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                // Signup Button
                ActionButton(
                  btnInfo: authState.isLoading
                      ? "Creating Account..."
                      : "Sign Up",
                  btnColor: AppColors.primaryBlue,
                  onTap: () {
                    final emailController = ref.read(authProvider).email;
                    final phoneController = ref.read(authProvider).phone;

                    if ((emailController.trim().isEmpty) &&
                        (phoneController.trim().isEmpty)) {
                      SnackbarService.showError(
                        context,
                        "Either email or phone is required",
                      );
                      return;
                    }

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
