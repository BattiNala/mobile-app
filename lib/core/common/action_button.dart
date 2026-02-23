import 'package:batti_nala/core/utils/colors.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String btnInfo;
  final VoidCallback onTap;
  const ActionButton({super.key, required this.btnInfo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: AppColors.adminRed,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: width * 0.3,
            ),
            child: Text(
              btnInfo,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
