import 'package:flutter/material.dart';
import 'package:batti_nala/core/constants/colors.dart';

class IssueStatusBar extends StatelessWidget {
  final String status;
  final String? rejectedReason;
  const IssueStatusBar({
    super.key,
    required this.status,
    this.rejectedReason,
  });

  Widget _buildRejectedReason(BuildContext context, Color statusColor) {
    if (rejectedReason == null || rejectedReason!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.adminRed,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Rejection Note: $rejectedReason',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.adminRed,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(color: color.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _getStatusDescription(status),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildRejectedReason(context, color),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN': return AppColors.adminRed;
      case 'IN_PROGRESS': return const Color(0xFF3B82F6);
      case 'ASSIGNED': return const Color(0xFF8B5CF6);
      case 'RESOLVED': return const Color(0xFF10B981);
      default: return AppColors.textMuted;
    }
  }

  IconData _getStatusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'open': return Icons.bolt_rounded;
      case 'in_progress': return Icons.published_with_changes_rounded;
      case 'assigned': return Icons.verified_user_rounded;
      case 'resolved': return Icons.check_circle_rounded;
      default: return Icons.info_rounded;
    }
  }

  String _getStatusDescription(String s) {
    switch (s.toLowerCase()) {
      case 'open': return 'Newly assigned mission. Review required.';
      case 'assigned': return 'Ownership taken. Prepare for execution.';
      case 'in_progress': return 'Work is active on the field.';
      case 'resolved': return 'Mission accomplished. Waiting for closure.';
      default: return 'Follow procedure for status updates.';
    }
  }
}
