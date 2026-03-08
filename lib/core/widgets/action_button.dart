import 'package:batti_nala/core/utils/colors.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String btnInfo;
  final Color? btnColor;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final bool isFullWidth;
  final double? fontSize;
  final double? borderRadius;

  const ActionButton({
    super.key,
    required this.btnInfo,
    required this.onTap,
    this.btnColor,
    this.width,
    this.height,
    this.margin,
    this.isFullWidth = true,
    this.fontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive calculations
    bool isTablet = screenWidth > 600;
    bool isSmallPhone = screenWidth < 360;

    // Adjust sizes based on screen size
    double responsiveFontSize =
        fontSize ?? (isTablet ? 28 : (isSmallPhone ? 18 : 20));

    double responsiveVerticalPadding =
        height ?? (isTablet ? 20 : (isSmallPhone ? 12 : 16));

    double responsiveHorizontalPadding = isTablet
        ? screenWidth * 0.15
        : screenWidth * 0.1;
    responsiveHorizontalPadding = responsiveHorizontalPadding.clamp(30, 100);

    double defaultBottomMargin = isSmallPhone
        ? screenHeight *
              0.02 // 2% for small phones
        : screenHeight * 0.03; // 3% for normal devices

    return Container(
      width: isFullWidth ? double.infinity : width,
      margin: margin ?? EdgeInsets.only(bottom: defaultBottomMargin),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenHeight * 0.005,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
      ),
      child: Material(
        color: btnColor ?? AppColors.adminRed,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: responsiveVerticalPadding,
              horizontal: responsiveHorizontalPadding,
            ),
            child: Text(
              btnInfo,
              style: TextStyle(
                fontSize: responsiveFontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.background,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
