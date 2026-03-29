import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/auth/view/input_label_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleVerify() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await ref.read(authNotifierProvider.notifier).verify();
        if (mounted) {
          final user = ref.read(authNotifierProvider).user;
          final route = user?.role == 'citizen'
              ? '/citizen-dashboard'
              : '/staff-dashboard';
          // ignore: use_build_context_synchronously
          context.go(route);
        }
      } catch (e) {
        // Error handled by listener in UI if needed, or by notifier
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Listen for verification success
    ref.listen<bool>(
      authNotifierProvider.select((state) => state.isVerified),
      (previous, next) {
        if (next && mounted) {
          SnackbarService.showSuccess(context, 'Account verified successfully!');
        }
      },
    );

    // Listen for error messages
    ref.listen<String?>(
      authNotifierProvider.select((state) => state.errorMessage),
      (previous, next) {
        if (next != null && next.isNotEmpty && mounted) {
          SnackbarService.showError(context, next);
          ref.read(authNotifierProvider.notifier).clearError();
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
                  mainText: 'Verify Account',
                  infoText: 'Enter the verification code sent to your email/phone',
                ),
                const SizedBox(height: 30),

                InputLabelWidget(
                  icon: FontAwesomeIcons.key,
                  inputType: TextInputType.number,
                  label: 'Verification Code',
                  hint: 'Enter 6-digit code',
                  onChanged: (val) => ref
                      .read(authNotifierProvider.notifier)
                      .updateVerificationCode(val),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the code';
                    }
                    if (value.length < 4) {
                      return 'Code is too short';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                ActionButton(
                  width: double.infinity,
                  label: authState.isLoading ? 'Verifying...' : 'Verify Now',
                  backgroundColor: AppColors.primaryBlue,
                  onPressed: _handleVerify,
                  isLoading: authState.isLoading,
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .resendVerification();
                        if (context.mounted) {
                          SnackbarService.showSuccess(
                            context,
                            'Verification code resent!',
                          );
                        }
                      } catch (e) {
                        // Error handled by listener
                      }
                    },
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Center(
                  child: TextButton(
                    onPressed: () {
                      ref.read(authNotifierProvider.notifier).logout();
                      context.go('/login');
                    },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(color: Colors.grey),
                    ),
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
