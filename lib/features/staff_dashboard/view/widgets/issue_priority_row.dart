import 'package:flutter/material.dart';
import 'package:batti_nala/core/constants/colors.dart';

class IssuePriorityRow extends StatelessWidget {
  final String priority;
  const IssuePriorityRow({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor(priority);
    return Row(
      children: [
        Icon(
          Icons.flag_rounded,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '${priority.toUpperCase()} Priority',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String p) => 
      p.toUpperCase() == 'HIGH' ? AppColors.adminRed : AppColors.primaryBlue;
}
