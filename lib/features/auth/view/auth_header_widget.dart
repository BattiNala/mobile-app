import 'package:batti_nala/core/constants/colors.dart';
import 'package:flutter/material.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String mainText;
  final String infoText;

  /// true = on dark gradient (white text); false = on light background (dark text)
  final bool isLight;

  const AuthHeaderWidget({
    super.key,
    required this.mainText,
    required this.infoText,
    this.isLight = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App logo mark
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white.withValues(alpha: 0.18)
                : AppColors.primaryBlueLight,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Image.asset(
            'assets/icons/battinala_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          mainText,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: isLight ? Colors.white : AppColors.textMain,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          infoText,
          style: TextStyle(
            fontSize: 15,
            color: isLight
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
