import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/auth/view/input_label_widget.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<bool>(
      authNotifierProvider.select((s) => s.isVerified),
      (_, next) {
        if (next && mounted) {
          SnackbarService.showSuccess(context, 'Account verified successfully!');
        }
      },
    );

    ref.listen<String?>(
      authNotifierProvider.select((s) => s.errorMessage),
      (_, next) {
        if (next != null && next.isNotEmpty && mounted) {
          SnackbarService.showError(context, next);
          ref.read(authNotifierProvider.notifier).clearError();
        }
      },
    );

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
                        const AuthHeaderWidget(
                          mainText: 'Verify Account',
                          infoText:
                              'Enter the code sent to your email or phone.',
                        ),
                        const SizedBox(height: 32),

                        // Glass card
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
                              child: Column(
                                children: [
                                  InputLabelWidget(
                                    icon: FontAwesomeIcons.key,
                                    inputType: TextInputType.number,
                                    label: 'Verification Code',
                                    hint: 'Enter 6-digit code',
                                    isGlass: true,
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
                                  const SizedBox(height: 24),
                                  ActionButton(
                                    width: double.infinity,
                                    label: authState.isLoading
                                        ? 'Verifying...'
                                        : 'Verify Now',
                                    backgroundColor: AppColors.adminRed,
                                    onPressed: _handleVerify,
                                    isLoading: authState.isLoading,
                                    borderRadius: 14,
                                    verticalPadding: 15,
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(
                                              authNotifierProvider.notifier,
                                            )
                                            .resendVerification();
                                        if (context.mounted) {
                                          SnackbarService.showSuccess(
                                            context,
                                            'Verification code resent!',
                                          );
                                        }
                                      } catch (_) {}
                                    },
                                    child: const Text(
                                      'Resend Code',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .logout();
                              context.go('/login');
                            },
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

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}
