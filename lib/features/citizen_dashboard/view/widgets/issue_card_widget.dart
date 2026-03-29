import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/issue_report/models/issue_model.dart';
import 'package:flutter/material.dart';

class IssueCardWidget extends StatelessWidget {
  final IssueModel issue;
  const IssueCardWidget({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final typeLower = issue.issueType.toLowerCase();
    final isElectricity = typeLower.contains('electricity');
    final isSewage =
        typeLower.contains('sewage') || typeLower.contains('drain');

    final accentColor = isElectricity
        ? AppColors.primaryBlue
        : isSewage
        ? const Color(0xFF006B3F)
        : AppColors.adminRed;

    final typeIcon = isElectricity
        ? Icons.electric_bolt
        : isSewage
        ? Icons.plumbing
        : Icons.report_problem;

    final statusColor = _getStatusColor(issue.status);
    final statusLabel = _getStatusLabel(issue.status);
    final priorityColor = _getPriorityColor(issue.issuePriority);

    final formattedTime = _formatDateTime(issue.createdAt);

    return Card(
      elevation: 1,
      color: AppColors.white,
      shadowColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderHover, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [accentColor, accentColor.withValues(alpha: 0.25)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderHover),
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          typeIcon,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.22,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                issue.issueLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              issue.issueType.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildDatePill(formattedTime),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 8.0),
                    child: Text(
                      'Description: ${issue.description}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMain,
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(label: statusLabel, color: statusColor),
                      _buildPriorityChip(
                        label: issue.issuePriority.toUpperCase(),
                        color: priorityColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildDatePill(String formattedTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            formattedTime,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Chip _buildStatusChip({required String label, required Color color}) {
    return Chip(
      avatar: Icon(_getStatusIcon(label), size: 16, color: color),
      label: Text(
        'Status: $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
      shape: const StadiumBorder(),
      padding: EdgeInsets.zero,
    );
  }

  Chip _buildPriorityChip({required String label, required Color color}) {
    return Chip(
      avatar: Icon(_getPriorityIcon(label), size: 16, color: color),
      label: Text(
        'Priority: $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
      shape: const StadiumBorder(),
      padding: EdgeInsets.zero,
    );
  }

  IconData _getStatusIcon(String statusLabel) {
    switch (statusLabel.toLowerCase()) {
      case 'open':
        return Icons.error_outline;
      case 'in progress':
        return Icons.timelapse;
      case 'assigned':
        return Icons.assignment_turned_in;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'closed':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return Icons.arrow_downward;
      case 'HIGH':
        return Icons.warning_amber_rounded;
      default:
        return Icons.flag_outlined;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'assigned':
        return 'Assigned';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return AppColors.adminRed;
      case 'IN_PROGRESS':
      case 'ASSIGNED':
        return AppColors.primaryBlue;
      case 'RESOLVED':
      case 'CLOSED':
        return const Color(0xFF16A34A);
      default:
        return AppColors.textMuted;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'LOW':
        return AppColors.primaryBlue800;
      case 'HIGH':
        return AppColors.adminRed;
      case 'NORMAL':
      default:
        return AppColors.primaryBlue;
    }
  }
}
