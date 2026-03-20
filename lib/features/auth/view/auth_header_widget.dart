import 'package:batti_nala/core/utils/colors.dart';
import 'package:flutter/material.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String mainText;
  final String infoText;
  const AuthHeaderWidget({
    super.key,
    required this.mainText,
    required this.infoText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mainText,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          infoText,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
