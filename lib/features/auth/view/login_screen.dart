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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    ref.listen(authProvider, (previous, next) {
      final errorMessage = next.errorMessage;
      if (errorMessage != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackbarService.showError(context, errorMessage);
          ref.read(authProvider.notifier).clearError();
        });
      }

      if (next.isLoading == false && next.errorMessage == null && mounted) {
        Navigator.pushReplacementNamed(context, '/staff_dashboard');
      }
    });
  }

  // Handle login logic
  Future<void> _handleLogin() async {
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.login();
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
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const AuthHeaderWidget(
                  mainText: "Welcome Back",
                  infoText: "Sign in to continue",
                ),
                const SizedBox(height: 30),

                // Email Field
                InputLabelWidget(
                  validator: AppValidators.validateEmail,
                  labelInfo: "Email/Phone",
                  hintText: "Enter your email or phone number",
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

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Login Button
                ActionButton(
                  btnInfo: authState.isLoading ? "Signing In..." : "Sign In",
                  btnColor: AppColors.primaryBlue,
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      _handleLogin();
                    }
                  },
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
            ref.read(authProvider.notifier).resetForm();
            Navigator.pushNamed(context, '/signup');
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
                TextSpan(
                  text: "Register",
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
