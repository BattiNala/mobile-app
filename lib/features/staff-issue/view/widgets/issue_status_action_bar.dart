import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/widgets/action_button.dart';
import 'package:batti_nala/features/staff-issue/controllers/employee_issue_detail_notifier.dart';

class IssueStatusActionBar extends ConsumerWidget {
  final String status;
  final String issueLabel;

  const IssueStatusActionBar({
    super.key,
    required this.status,
    required this.issueLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusUpper = status.toUpperCase();
    String? nextStatus;
    String label = '';
    Color color = AppColors.primaryBlue;

    if (statusUpper == 'OPEN' || statusUpper == 'ASSIGNED') {
      nextStatus = 'IN_PROGRESS';
      label = 'Start Work';
      color = const Color(0xFF3B82F6);
    } else if (statusUpper == 'IN_PROGRESS') {
      nextStatus = 'RESOLVED';
      label = 'Mark Resolved';
      color = const Color(0xFF10B981);
    }

    if (nextStatus == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ActionButton(
        label: label,
        backgroundColor: color,
        width: double.infinity,
        onPressed: () async {
          final success = await ref
              .read(employeeIssueDetailProvider(issueLabel).notifier)
              .updateStatus(nextStatus!);

          if (context.mounted && !success) {
            SnackbarService.showError(context, 'Failed to update status');
          }
        },
      ),
    );
  }
}
