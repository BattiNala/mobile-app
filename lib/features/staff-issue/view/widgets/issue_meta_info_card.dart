import 'package:flutter/material.dart';
import 'package:batti_nala/core/constants/colors.dart';

class IssueMetaInfoCard extends StatelessWidget {
  final DateTime createdAt;
  final String? assignedTo;
  
  const IssueMetaInfoCard({
    super.key, 
    required this.createdAt, 
    this.assignedTo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildMetaRow(
            Icons.calendar_today_rounded,
            'Assigned on',
            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
          ),
          if (assignedTo != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.white),
            ),
            _buildMetaRow(
              Icons.engineering_rounded,
              'Assigned to',
              assignedTo!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text('$label   ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain)),
      ],
    );
  }
}
