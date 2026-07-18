import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> showLogoutSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _LogoutSheet(ref: ref),
  );
}

class _LogoutSheet extends StatefulWidget {
  final WidgetRef ref;
  const _LogoutSheet({required this.ref});

  @override
  State<_LogoutSheet> createState() => _LogoutSheetState();
}

class _LogoutSheetState extends State<_LogoutSheet> {
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    await widget.ref.read(authNotifierProvider.notifier).logout();
    if (mounted) {
      Navigator.pop(context);
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 +
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // App logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Image.asset(
                  'assets/icons/battinala_logo.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'Log Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextMain : AppColors.textMain,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                'You will be signed out of your account.\nYou can log back in anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface2
                              : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _logout,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.adminRed,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.adminRed.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Log Out',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
