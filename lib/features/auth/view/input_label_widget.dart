import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InputLabelWidget extends ConsumerWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextCapitalization? textCapitalization;
  final TextInputType? inputType;
  final bool isPassword;

  /// When true the widget renders white-on-glass text for gradient backgrounds.
  final bool isGlass;

  final String? Function(String?)? validator;
  final void Function(String) onChanged;
  final TextEditingController? controller;
  final Iterable<String>? autofillHints;

  const InputLabelWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.inputType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.isPassword = false,
    this.isGlass = false,
    this.controller,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelColor = isGlass ? Colors.white : AppColors.textMain;
    final iconColor = isGlass ? Colors.white60 : Colors.grey;
    final fillColor = isGlass
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.background;
    final borderColor = isGlass
        ? Colors.white.withValues(alpha: 0.25)
        : AppColors.border;
    final focusedBorderColor =
        isGlass ? Colors.white : AppColors.primaryBlue;
    final textColor = isGlass ? Colors.white : AppColors.textMain;
    final hintColor = isGlass ? Colors.white38 : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          autofillHints: autofillHints,
          controller: controller,
          validator: validator,
          keyboardType: inputType,
          style: TextStyle(color: textColor),
          obscureText: isPassword
              ? (label.toLowerCase().contains('confirm')
                    ? ref
                          .watch(authNotifierProvider)
                          .isConfirmPasswordObscured
                    : ref.watch(authNotifierProvider).isPasswordObscured)
              : false,
          onChanged: onChanged,
          textCapitalization: textCapitalization!,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fillColor,
            prefixIcon: Icon(icon, color: iconColor, size: 18),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () {
                      if (label.toLowerCase().contains('confirm')) {
                        ref
                            .read(authNotifierProvider.notifier)
                            .toggleConfirmPasswordVisibility();
                      } else {
                        ref
                            .read(authNotifierProvider.notifier)
                            .togglePasswordVisibility();
                      }
                    },
                    icon: Icon(
                      (label.toLowerCase().contains('confirm')
                              ? ref
                                    .watch(authNotifierProvider)
                                    .isConfirmPasswordObscured
                              : ref
                                    .watch(authNotifierProvider)
                                    .isPasswordObscured)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: iconColor,
                      size: 20,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusedBorderColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.adminRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.adminRed,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
