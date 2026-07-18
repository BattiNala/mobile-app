import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/utils/validators.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/auth/view/input_label_widget.dart';
import 'package:batti_nala/features/shared/models/user_model.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _keyForm = GlobalKey<FormState>();

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
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
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

  Future<void> _handleSignUp() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    if (_keyForm.currentState?.validate() ?? false) {
      final authState = ref.read(authNotifierProvider);
      try {
        await authNotifier.register(
          username: authState.email ?? '',
          password: authState.password,
          name: authState.name,
          phoneNumber: authState.phone,
          email: authState.email ?? '',
          homeAddress: authState.homeAddress,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<User?>(authNotifierProvider.select((s) => s.user), (prev, next) {
      if (next != null && prev == null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final route = next.role == 'citizen'
                ? '/citizen-dashboard'
                : '/staff-dashboard';
            context.go(route);
          }
        });
      }
    });

    ref.listen<String?>(
      authNotifierProvider.select((s) => s.errorMessage),
      (_, next) {
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
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(gradient: AppColors.welcomeGradient),
          ),

          // Decorative circles
          Positioned(
            top: -60,
            left: -80,
            child: _circle(260, 0.12),
          ),
          Positioned(
            bottom: 60,
            right: -70,
            child: _circle(200, 0.09),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _keyForm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const AuthHeaderWidget(
                          mainText: 'Create Account',
                          infoText: 'Sign up to get started',
                        ),
                        const SizedBox(height: 28),

                        // Glass card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.14),
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
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: AppValidators.validateName,
                                    icon: FontAwesomeIcons.user,
                                    inputType: TextInputType.name,
                                    label: 'Full Name',
                                    hint: 'Enter your full name',
                                    isGlass: true,
                                    onChanged: (val) => ref
                                        .read(authNotifierProvider.notifier)
                                        .updateName(val),
                                  ),
                                  const SizedBox(height: 18),
                                  InputLabelWidget(
                                    validator: AppValidators.validatePhone,
                                    icon: FontAwesomeIcons.phone,
                                    inputType: TextInputType.phone,
                                    label: 'Phone Number',
                                    hint: 'Enter your phone number',
                                    isGlass: true,
                                    onChanged: (val) => ref
                                        .read(authNotifierProvider.notifier)
                                        .updatePhone(val),
                                  ),
                                  const SizedBox(height: 18),
                                  InputLabelWidget(
                                    validator: AppValidators.validateEmail,
                                    icon: FontAwesomeIcons.envelope,
                                    inputType: TextInputType.emailAddress,
                                    label: 'Email Address',
                                    hint: 'Enter your email',
                                    isGlass: true,
                                    onChanged: (val) => ref
                                        .read(authNotifierProvider.notifier)
                                        .updateEmail(val),
                                  ),
                                  const SizedBox(height: 18),
                                  InputLabelWidget(
                                    validator: AppValidators.validatePassword,
                                    icon: FontAwesomeIcons.lock,
                                    inputType: TextInputType.visiblePassword,
                                    isPassword: true,
                                    label: 'Password',
                                    hint: 'Create a password',
                                    isGlass: true,
                                    onChanged: (val) => ref
                                        .read(authNotifierProvider.notifier)
                                        .updatePassword(val),
                                  ),
                                  const SizedBox(height: 18),
                                  InputLabelWidget(
                                    validator: (value) =>
                                        AppValidators.validateConfirmPassword(
                                      value,
                                      ref
                                          .read(authNotifierProvider)
                                          .password,
                                    ),
                                    icon: FontAwesomeIcons.lock,
                                    inputType: TextInputType.visiblePassword,
                                    isPassword: true,
                                    label: 'Confirm Password',
                                    hint: 'Repeat your password',
                                    isGlass: true,
                                    onChanged: (val) => ref
                                        .read(authNotifierProvider.notifier)
                                        .updateConfirmPassword(val),
                                  ),
                                  const SizedBox(height: 18),
                                  InputLabelWidget(
                                    icon: FontAwesomeIcons.locationDot,
                                    inputType: TextInputType.streetAddress,
                                    label: 'Home Address (Optional)',
                                    hint: 'e.g. Kathmandu, Ward 10',
                                    textCapitalization:
                                        TextCapitalization.words,
                                    isGlass: true,
                                    onChanged: (val) => ref
                                        .read(authNotifierProvider.notifier)
                                        .updateHomeAddress(val),
                                  ),
                                  const SizedBox(height: 24),
                                  ActionButton(
                                    width: double.infinity,
                                    label: authState.isLoading
                                        ? 'Creating Account...'
                                        : 'Sign Up',
                                    backgroundColor: AppColors.adminRed,
                                    onPressed: () {
                                      if (_keyForm.currentState!.validate()) {
                                        _handleSignUp();
                                      }
                                    },
                                    isLoading: authState.isLoading,
                                    borderRadius: 14,
                                    verticalPadding: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _buildLoginLink(),
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

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          ref.read(authNotifierProvider.notifier).resetForm();
          context.pop();
        },
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 15),
            children: [
              const TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: Colors.white60),
              ),
              TextSpan(
                text: 'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
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
