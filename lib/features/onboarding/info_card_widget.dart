import 'package:batti_nala/core/constants/colors.dart';
import 'package:flutter/material.dart';

class InfoCardWidget extends StatelessWidget {
  final IconData icon;
  final String heading;
  final String info;

  const InfoCardWidget({
    super.key,
    required this.icon,
    required this.heading,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.045),
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 10,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: .8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: screenWidth * 0.12,
            width: screenWidth * 0.12,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              color: AppColors.primaryBlue900.withValues(alpha: .8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: AppColors.background.withValues(alpha: .8),
              size: 30,
            ),
          ),
          SizedBox(width: screenWidth * 0.08),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: AppColors.background,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  info,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.background,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
