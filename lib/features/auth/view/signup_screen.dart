import 'package:batti_nala/core/common/action_button.dart';
import 'package:batti_nala/core/utils/colors.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/auth/view/input_label_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              AuthHeaderWidget(
                mainText: "Create Account",
                infoText: "Join BattiNala today",
              ),
              const SizedBox(height: 30),
              InputLabelWidget(
                labelInfo: "Full Name",
                controller: _nameController,
                icon: FontAwesomeIcons.user,
                hintText: "Hari Bahadur Nepal",
              ),
              const SizedBox(height: 20),
              InputLabelWidget(
                labelInfo: "Email Address",
                controller: _emailController,
                icon: FontAwesomeIcons.envelope,
                hintText: "Enter your email",
              ),
              const SizedBox(height: 20),
              InputLabelWidget(
                labelInfo: "Password",
                controller: _passwordController,
                icon: FontAwesomeIcons.lock,
                hintText: "Enter your password",
                isPassword: true,
              ),
              const SizedBox(height: 40),
              InputLabelWidget(
                labelInfo: "Confirm Password",
                controller: _confirmPasswordController,
                icon: FontAwesomeIcons.lock,
                hintText: "Re-enter your password",
                isPassword: true,
              ),
              const SizedBox(height: 40),
              ActionButton(
                btnInfo: "Sign Up",
                btnColor: AppColors.primaryBlue,
                onTap: () {},
              ),
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/login'),
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
