import 'package:batti_nala/core/constants/colors.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final IconData? iconPath;
  final double? iconHeight;
  final double? iconWidth;
  final double? labelSize;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final double borderRadius;
  final BorderSide? borderSide;
  final double? width;
  final double verticalPadding;

  const ActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.iconPath,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.iconHeight = 16,
    this.iconWidth = 16,
    this.labelSize = 14,
    this.borderRadius = 8,
    this.borderSide,
    this.width,
    this.verticalPadding = 12,
  });

  /// Factory constructor for creating an outlined button style
  factory ActionButton.outline({
    required String label,
    double labelSize = 14,
    VoidCallback? onPressed,
    Color color = AppColors.textMain,
  }) {
    return ActionButton(
      label: label,
      labelSize: labelSize,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      textColor: color,
      borderSide: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on state
    final effectiveBgColor = backgroundColor ?? AppColors.adminRed;
    final effectiveTextColor = textColor ?? Colors.white;

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBgColor,
          disabledBackgroundColor: effectiveBgColor.withValues(alpha: 0.6),
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: 16,
          ),
          elevation: 0,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: effectiveTextColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconPath != null) ...[
                    Icon(iconPath, size: iconHeight, color: effectiveTextColor),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: effectiveTextColor,
                        fontSize: labelSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
