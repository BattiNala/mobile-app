import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/widgets/loading_indicator.dart';
import 'package:batti_nala/features/staff-issue/controllers/employee_issue_detail_notifier.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_detail_header.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_status_bar.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_priority_row.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_location_card.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_image_gallery.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_meta_info_card.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_status_action_bar.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/section_heading.dart';
import 'package:go_router/go_router.dart';

class EmployeeIssueDetailView extends ConsumerWidget {
  final String issueLabel;

  const EmployeeIssueDetailView({super.key, required this.issueLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeeIssueDetailProvider(issueLabel));

    return Scaffold(
      backgroundColor: Colors.white,
      body: state.when(
        loading: () => const LoadingIndicator(),
        error: (err, stack) =>
            const Center(child: Text('Error in fetching issue details')),
        data: (issue) => _buildContent(context, issue, ref),
      ),
      bottomNavigationBar: state.when(
        loading: () => null,
        error: (err, stack) => null,
        data: (issue) =>
            IssueStatusActionBar(status: issue.status, issueLabel: issueLabel),
      ),
    );
  }

  Widget _buildContent(BuildContext context, var issue, WidgetRef ref) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        IssueDetailHeader(
          issueLabel: issue.issueLabel,
          issueType: issue.issueType,
          rejectedReason: issue.rejectedReason,
          onReportFalse: () => _showReportFalseDialog(context, ref),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IssueStatusBar(
                status: issue.status,
                rejectedReason: issue.rejectedReason,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IssuePriorityRow(priority: issue.issuePriority),
                    const SizedBox(height: 32),
                    const SectionHeading(title: 'Problem Description'),
                    const SizedBox(height: 12),
                    Text(
                      issue.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMain.withValues(alpha: 0.9),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const SectionHeading(title: 'Mission Location'),
                    const SizedBox(height: 16),
                    IssueLocationCard(
                      location: issue.issueLocation,
                      latitude: issue.latitude,
                      longitude: issue.longitude,
                      onTap: () => context.push('/mission-map', extra: issue),
                    ),
                    const SizedBox(height: 40),
                    if (issue.attachments.isNotEmpty) ...[
                      const SectionHeading(title: 'Visual Evidence'),
                      const SizedBox(height: 16),
                      IssueImageGallery(
                        urls: List<String>.from(issue.attachments),
                      ),
                      const SizedBox(height: 40),
                    ],
                    IssueMetaInfoCard(
                      createdAt: issue.createdAt,
                      assignedTo: issue.assignedTo,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReportFalseDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flag_rounded, color: AppColors.adminRed),
            SizedBox(width: 12),
            Text(
              'Report False Issue',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provide a reason why this issue is being reported as false.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              final notifier = ref.read(
                employeeIssueDetailProvider(issueLabel).notifier,
              );
              final success = await notifier.reportFalseIssue(
                reasonController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Issue reported as false successfully'
                          : 'Failed to report issue',
                    ),
                    backgroundColor: success
                        ? Colors.green
                        : AppColors.adminRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
