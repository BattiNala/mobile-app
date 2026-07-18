import 'package:batti_nala/core/constants/colors.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatefulWidget {
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
  final Gradient? gradient;

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
    this.labelSize = 15,
    this.borderRadius = 14,
    this.borderSide,
    this.width,
    this.verticalPadding = 15,
    this.gradient,
  });

  factory ActionButton.outline({
    required String label,
    double labelSize = 14,
    VoidCallback? onPressed,
    Color color = AppColors.primaryBlue,
    double borderRadius = 14,
  }) {
    return ActionButton(
      label: label,
      labelSize: labelSize,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      textColor: color,
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
    );
  }

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.backgroundColor ?? AppColors.adminRed;
    final effectiveText = widget.textColor ?? Colors.white;
    final hasGradient = widget.gradient != null;
    final isDisabled = widget.isLoading || widget.onPressed == null;

    final glowColor = hasGradient ? AppColors.primaryBlue : effectiveBg;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: SizedBox(
          width: widget.width,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              gradient: hasGradient ? widget.gradient : null,
              color: hasGradient
                  ? null
                  : (isDisabled
                      ? effectiveBg.withValues(alpha: 0.55)
                      : effectiveBg),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.borderSide != null
                  ? Border.fromBorderSide(widget.borderSide!)
                  : null,
              boxShadow: isDisabled || effectiveBg == Colors.transparent
                  ? null
                  : [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: _isPressed ? 0.45 : 0.28,
                        ),
                        blurRadius: _isPressed ? 14 : 20,
                        offset: const Offset(0, 5),
                        spreadRadius: _isPressed ? 0 : -2,
                      ),
                    ],
            ),
            padding: EdgeInsets.symmetric(
              vertical: widget.verticalPadding,
              horizontal: 20,
            ),
            child: widget.isLoading
                ? Center(child: _LoadingDots(color: effectiveText))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.iconPath != null) ...[
                        Icon(
                          widget.iconPath,
                          size: widget.iconHeight,
                          color: isDisabled
                              ? effectiveText.withValues(alpha: 0.5)
                              : effectiveText,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDisabled
                                ? effectiveText.withValues(alpha: 0.5)
                                : effectiveText,
                            fontSize: widget.labelSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final start = i * 0.2;
          final end = start + 0.4;
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              double y = 0;
              if (t >= start && t <= end) {
                final progress = (t - start) / 0.4;
                y = -6 * _mathSin(progress * 3.14159);
              }
              return Transform.translate(
                offset: Offset(0, y),
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  double _mathSin(double x) {
    // approximation good enough for 0..π
    return x < 0
        ? 0
        : x > 3.14159
            ? 0
            : 4 * x * (3.14159 - x) / (3.14159 * 3.14159);
  }
}
