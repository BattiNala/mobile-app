import 'package:batti_nala/core/utils/colors.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InputLabelWidget extends ConsumerWidget {
  final String labelInfo;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final AuthFieldType fieldType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;

  const InputLabelWidget({
    super.key,
    required this.validator,
    this.capitalization = TextCapitalization.none,
    required this.labelInfo,
    required this.hintText,
    required this.icon,
    required this.fieldType,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // Get the current value based on field type
    String getCurrentValue() {
      switch (fieldType) {
        case AuthFieldType.name:
          return authState.name;
        case AuthFieldType.phone:
          return authState.phone;
        case AuthFieldType.email:
          return authState.email;
        case AuthFieldType.password:
          return authState.password;
        case AuthFieldType.confirmPassword:
          return authState.confirmPassword;
      }
    }

    // Update handler
    void onChanged(String value) {
      switch (fieldType) {
        case AuthFieldType.name:
          authNotifier.updateName(value);
          break;
        case AuthFieldType.phone:
          authNotifier.updatePhone(value);
          break;
        case AuthFieldType.email:
          authNotifier.updateEmail(value);
          break;
        case AuthFieldType.password:
          authNotifier.updatePassword(value);
          break;
        case AuthFieldType.confirmPassword:
          authNotifier.updateConfirmPassword(value);
          break;
      }
    }

    // Get obscure text state
    bool getObscureText() {
      if (!isPassword) return false;

      switch (fieldType) {
        case AuthFieldType.password:
          return authState.isPasswordObscured;
        case AuthFieldType.confirmPassword:
          return authState.isConfirmPasswordObscured;
        default:
          return false;
      }
    }

    // Toggle visibility
    void toggleVisibility() {
      switch (fieldType) {
        case AuthFieldType.password:
          authNotifier.togglePasswordVisibility();
          break;
        case AuthFieldType.confirmPassword:
          authNotifier.toggleConfirmPasswordVisibility();
          break;
        default:
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            labelInfo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ),
        TextFormField(
          textCapitalization: capitalization,
          validator: validator,
          onChanged: onChanged,
          initialValue: getCurrentValue(),
          obscureText: getObscureText(),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: FaIcon(icon, size: 18, color: Colors.grey),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: FaIcon(
                      getObscureText()
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: toggleVisibility,
                  )
                : null,
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[300]!, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// Auth field types
enum AuthFieldType { name, phone, email, password, confirmPassword }
