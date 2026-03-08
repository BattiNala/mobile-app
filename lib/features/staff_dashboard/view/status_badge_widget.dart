import 'package:batti_nala/features/staff_dashboard/model/issue_model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StatusBadge extends StatelessWidget {
  final IssueStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case IssueStatus.pending:
        color = Colors.orange;
        icon = FontAwesomeIcons.clock;
        text = 'Pending';
        break;
      case IssueStatus.inProgress:
        color = Colors.blue;
        icon = FontAwesomeIcons.spinner;
        text = 'In Progress';
        break;
      case IssueStatus.resolved:
        color = Colors.green;
        icon = FontAwesomeIcons.circleCheck;
        text = 'Resolved';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
