import 'package:batti_nala/core/utils/colors.dart';
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
  final String? Function(String?)? validator;
  final void Function(String) onChanged;

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          validator: validator,
          keyboardType: inputType,
          obscureText: isPassword
              ? (ref.watch(authProvider).isPasswordObscured)
              : false,
          onChanged: onChanged,
          textCapitalization: textCapitalization!,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () {
                      if (label.toLowerCase().contains('confirm')) {
                        ref
                            .read(authProvider.notifier)
                            .toggleConfirmPasswordVisibility();
                      } else {
                        ref
                            .read(authProvider.notifier)
                            .togglePasswordVisibility();
                      }
                    },
                    icon: ref.watch(authProvider).isPasswordObscured
                        ? const Icon(Icons.visibility_off, color: Colors.grey)
                        : const Icon(Icons.visibility, color: Colors.grey),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
