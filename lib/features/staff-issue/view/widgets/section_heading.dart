import 'package:flutter/material.dart';
import 'package:batti_nala/core/constants/colors.dart';

class SectionHeading extends StatelessWidget {
  final String title;
  const SectionHeading({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.textMain,
      ),
    );
  }
}
