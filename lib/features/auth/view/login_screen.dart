import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:batti_nala/core/utils/validators.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/view/auth_header_widget.dart';
import 'package:batti_nala/features/auth/view/input_label_widget.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

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
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    if (_formKey.currentState?.validate() ?? false) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      authNotifier.updateEmail(username);
      authNotifier.updatePassword(password);
      try {
        await authNotifier.login(username, password);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<String?>(authNotifierProvider.select((s) => s.errorMessage), (
      _,
      next,
    ) {
      if (next != null && next.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            SnackbarService.showError(context, next);
            ref.read(authNotifierProvider.notifier).clearError();
          }
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.welcomeGradient,
            ),
          ),

          // Decorative circles
          const Positioned(
            top: -80,
            right: -60,
            child: _GlowCircle(size: 280, opacity: 0.15),
          ),
          const Positioned(
            bottom: 100,
            left: -80,
            child: _GlowCircle(size: 220, opacity: 0.1),
          ),
          const Positioned(
            top: 180,
            left: -40,
            child: _GlowCircle(size: 140, opacity: 0.08),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 52),

                          // Logo + greeting
                          const AuthHeaderWidget(
                            mainText: 'Welcome Back',
                            infoText: 'Sign in to continue',
                          ),

                          const SizedBox(height: 36),

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
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    InputLabelWidget(
                                      autofillHints: const [
                                        AutofillHints.username,
                                        AutofillHints.email,
                                      ],
                                      controller: _usernameController,
                                      validator: AppValidators.validateUsername,
                                      icon: FontAwesomeIcons.envelope,
                                      inputType: TextInputType.emailAddress,
                                      label: 'Email / Phone',
                                      hint: 'Enter your email or phone',
                                      onChanged: (val) => ref
                                          .read(authNotifierProvider.notifier)
                                          .updateEmail(val),
                                      isGlass: true,
                                    ),

                                    const SizedBox(height: 20),

                                    InputLabelWidget(
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      controller: _passwordController,
                                      validator: AppValidators.validatePassword,
                                      icon: FontAwesomeIcons.lock,
                                      inputType: TextInputType.visiblePassword,
                                      isPassword: true,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      onChanged: (val) => ref
                                          .read(authNotifierProvider.notifier)
                                          .updatePassword(val),
                                      isGlass: true,
                                    ),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () =>
                                            context.push('/password-reset'),
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    ActionButton(
                                      width: double.infinity,
                                      label: authState.isLoading
                                          ? 'Signing In...'
                                          : 'Sign In',
                                      backgroundColor: AppColors.adminRed,
                                      onPressed: _handleLogin,
                                      isLoading: authState.isLoading,
                                      borderRadius: 14,
                                      verticalPadding: 15,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildRegisterLink(),
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          ref.read(authNotifierProvider.notifier).resetForm();
          context.push('/signup');
        },
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 15),
            children: [
              const TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: Colors.white60),
              ),
              TextSpan(
                text: 'Register',
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
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
