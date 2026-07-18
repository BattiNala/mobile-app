import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/utils/validators.dart';
import 'package:batti_nala/features/auth/controllers/password_reset_notifier.dart';
import 'package:batti_nala/features/auth/controllers/password_reset_state.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _newPasswordObscured = true;
  bool _confirmPasswordObscured = true;

  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(passwordResetProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _reAnimate() {
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PasswordResetState>(passwordResetProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          SnackbarService.showError(context, next.errorMessage!);
          ref.read(passwordResetProvider.notifier).clearError();
        });
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          SnackbarService.showSuccess(context, next.successMessage!);
          ref.read(passwordResetProvider.notifier).clearError();
          context.go('/login');
        });
      }
      // Re-animate when step changes
      if (previous?.step != next.step) {
        _reAnimate();
      }
    });

    final state = ref.watch(passwordResetProvider);
    final controller = ref.read(passwordResetProvider.notifier);

    final (headerText, infoText, cardContent) = switch (state.step) {
      PasswordResetStep.requestOtp => (
          'Reset Password',
          'Enter your email or phone to receive an OTP.',
          _requestStep(state, controller),
        ),
      PasswordResetStep.verifyOtp => (
          'Verify OTP',
          'Enter the code sent to your email or phone.',
          _verifyStep(state, controller),
        ),
      PasswordResetStep.confirmPassword => (
          'New Password',
          'Set a strong new password for your account.',
          _confirmStep(state, controller),
        ),
    };

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.welcomeGradient),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _circle(280, 0.13),
          ),
          Positioned(
            bottom: 80,
            left: -70,
            child: _circle(200, 0.08),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 52),
                        AuthHeaderWidget(
                          mainText: headerText,
                          infoText: infoText,
                        ),
                        const SizedBox(height: 32),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: cardContent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text(
                              'Back to Login',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestStep(PasswordResetState state, controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _glassField(
          controller: _usernameController,
          hint: 'Email or phone number',
          label: 'Email / Phone',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: AppValidators.validateUsername,
          onChanged: controller.updateUsername,
        ),
        const SizedBox(height: 20),
        ActionButton(
          width: double.infinity,
          label: state.isLoading ? 'Sending...' : 'Send OTP',
          backgroundColor: AppColors.adminRed,
          onPressed: () {
            if (_formKey.currentState!.validate()) controller.requestOtp();
          },
          isLoading: state.isLoading,
          borderRadius: 14,
          verticalPadding: 15,
        ),
      ],
    );
  }

  Widget _verifyStep(PasswordResetState state, controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _glassField(
          controller: _otpController,
          hint: 'Enter OTP code',
          label: 'OTP Code',
          icon: Icons.lock_open_rounded,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'OTP is required';
            if (!RegExp(r'^\d{4,}$').hasMatch(val.trim())) {
              return 'Enter a valid OTP';
            }
            return null;
          },
          onChanged: controller.updateOtpCode,
        ),
        const SizedBox(height: 20),
        ActionButton(
          width: double.infinity,
          label: state.isLoading ? 'Verifying...' : 'Verify OTP',
          backgroundColor: AppColors.adminRed,
          onPressed: () {
            if (_formKey.currentState!.validate()) controller.verifyOtp();
          },
          isLoading: state.isLoading,
          borderRadius: 14,
          verticalPadding: 15,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: state.isLoading ? null : controller.requestOtp,
            child: const Text(
              'Resend OTP',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmStep(PasswordResetState state, controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _glassField(
          controller: _newPasswordController,
          hint: 'New password',
          label: 'New Password',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.visiblePassword,
          obscureText: _newPasswordObscured,
          validator: AppValidators.validatePassword,
          onChanged: controller.updateNewPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _newPasswordObscured ? Icons.visibility_off : Icons.visibility,
              color: Colors.white60,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _newPasswordObscured = !_newPasswordObscured),
          ),
        ),
        const SizedBox(height: 18),
        _glassField(
          controller: _confirmPasswordController,
          hint: 'Confirm new password',
          label: 'Confirm Password',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.visiblePassword,
          obscureText: _confirmPasswordObscured,
          validator: (val) => AppValidators.validateConfirmPassword(
            val,
            state.newPassword,
          ),
          onChanged: controller.updateConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _confirmPasswordObscured
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: Colors.white60,
              size: 20,
            ),
            onPressed: () => setState(
              () => _confirmPasswordObscured = !_confirmPasswordObscured,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ActionButton(
          width: double.infinity,
          label: state.isLoading ? 'Resetting...' : 'Reset Password',
          backgroundColor: AppColors.adminRed,
          onPressed: () {
            if (_formKey.currentState!.validate()) controller.confirmReset();
          },
          isLoading: state.isLoading,
          borderRadius: 14,
          verticalPadding: 15,
        ),
      ],
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
    required void Function(String) onChanged,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.12),
            prefixIcon: Icon(icon, color: Colors.white60, size: 20),
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.adminRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.adminRed, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}
