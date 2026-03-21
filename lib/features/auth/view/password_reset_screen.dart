import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/utils/validators.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/features/auth/controllers/password_reset_notifier.dart';
import 'package:batti_nala/features/auth/controllers/password_reset_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _newPasswordObscured = true;
  bool _confirmPasswordObscured = true;

  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
    });
    final state = ref.watch(passwordResetProvider);
    final controller = ref.read(passwordResetProvider.notifier);

    Widget requestStep() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset Password',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email/phone to receive an OTP.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _usernameController,
            validator: AppValidators.validateUsername,
            keyboardType: TextInputType.emailAddress,
            onChanged: controller.updateUsername,
            decoration: InputDecoration(
              labelText: 'Email/Phone',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ActionButton(
            width: double.infinity,
            label: state.isLoading ? 'Sending...' : 'Send OTP',
            backgroundColor: AppColors.primaryBlue,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                controller.requestOtp();
              }
            },
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to login'),
          ),
        ],
      );
    }

    Widget verifyStep() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify OTP',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the OTP sent to your email/phone.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _otpController,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'OTP is required';
              if (!RegExp(r'^\d{4,}$').hasMatch(val.trim())) {
                return 'Enter a valid OTP';
              }
              return null;
            },
            keyboardType: TextInputType.number,
            onChanged: controller.updateOtpCode,
            decoration: InputDecoration(
              labelText: 'OTP Code',
              prefixIcon: const Icon(Icons.verified_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ActionButton(
            width: double.infinity,
            label: state.isLoading ? 'Verifying...' : 'Verify OTP',
            backgroundColor: AppColors.primaryBlue,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                controller.verifyOtp();
              }
            },
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: state.isLoading
                ? null
                : () {
                    controller.requestOtp();
                  },
            child: const Text('Resend OTP'),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to login'),
          ),
        ],
      );
    }

    Widget confirmStep() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Password',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a new password for your account.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _newPasswordController,
            validator: AppValidators.validatePassword,
            obscureText: _newPasswordObscured,
            onChanged: controller.updateNewPassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _newPasswordObscured = !_newPasswordObscured;
                  });
                },
                icon: Icon(
                  _newPasswordObscured
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            validator: (val) =>
                AppValidators.validateConfirmPassword(val, state.newPassword),
            obscureText: _confirmPasswordObscured,
            onChanged: controller.updateConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _confirmPasswordObscured = !_confirmPasswordObscured;
                  });
                },
                icon: Icon(
                  _confirmPasswordObscured
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ActionButton(
            width: double.infinity,
            label: state.isLoading ? 'Resetting...' : 'Reset Password',
            backgroundColor: AppColors.primaryBlue,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                controller.confirmReset();
              }
            },
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to login'),
          ),
        ],
      );
    }

    Widget body;
    switch (state.step) {
      case PasswordResetStep.requestOtp:
        body = requestStep();
        break;
      case PasswordResetStep.verifyOtp:
        body = verifyStep();
        break;
      case PasswordResetStep.confirmPassword:
        body = confirmStep();
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Form(key: _formKey, child: body),
        ),
      ),
    );
  }
}
