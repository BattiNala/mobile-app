import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/services/snackbar_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batti_nala/features/shared/widgets/loading_indicator.dart';
import 'package:batti_nala/features/staff-issue/controllers/employee_issue_detail_notifier.dart';
import 'package:batti_nala/features/shared/widgets/issue_location_card.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_detail_header.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_status_widgets.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/status_indicators.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_image_gallery.dart';
import 'package:batti_nala/features/staff-issue/view/widgets/issue_meta_info_card.dart';
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
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(employeeIssueDetailProvider(issueLabel).notifier)
            .fetchIssueDetail();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          IssueDetailHeader(
            issueLabel: issue.issueLabel,
            issueType: issue.issueType,
            rejectedReason: issue.rejectedReason,
            onReportFalse: () => _showReportFalseDialog(context, ref),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverToBoxAdapter(
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
                          reporttedBy: issue.reportedBy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportFalseDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _ReportFalseSheet(
        issueLabel: issueLabel,
        ref: ref,
        onSuccess: () {
          context.pushNamed('employee-dashboard');
          SnackbarService.showSuccess(
            context,
            'Issue reported as false successfully',
          );
        },
        onError: () {
          context.pushNamed('employee-dashboard');
          SnackbarService.showError(
            context,
            'Failed to report issue as false',
          );
        },
      ),
    );
  }
}

// ─── Report False Bottom Sheet ────────────────────────────────────────────────

class _ReportFalseSheet extends StatefulWidget {
  final String issueLabel;
  final WidgetRef ref;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const _ReportFalseSheet({
    required this.issueLabel,
    required this.ref,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_ReportFalseSheet> createState() => _ReportFalseSheetState();
}

class _ReportFalseSheetState extends State<_ReportFalseSheet> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(
      () => setState(() => _charCount = _reasonController.text.length),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;
    setState(() => _isLoading = true);

    final notifier = widget.ref.read(
      employeeIssueDetailProvider(widget.issueLabel).notifier,
    );
    final success = await notifier.reportFalseIssue(reason);

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        widget.onSuccess();
      } else {
        widget.onError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.adminRed.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/icons/battinala_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report False Issue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextMain
                              : AppColors.textMain,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        widget.issueLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Warning banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.adminRed.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.adminRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.adminRed.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This action marks the issue as rejected. '
                        'The citizen will be notified with your reason.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.adminRed.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reason label
              Text(
                'Reason',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Text field
              TextField(
                controller: _reasonController,
                maxLines: 4,
                maxLength: 300,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? AppColors.darkTextMain : AppColors.textMain,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'e.g. The reported location does not match any actual infrastructure issue…',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMuted,
                    height: 1.5,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface2.withValues(alpha: 0.6)
                      : AppColors.background,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.adminRed,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Char count
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$_charCount / 300',
                    style: TextStyle(
                      fontSize: 11,
                      color: _charCount > 270
                          ? AppColors.adminRed
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textMuted),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface2
                              : const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isLoading ||
                              _reasonController.text.trim().isEmpty
                          ? null
                          : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _reasonController.text.trim().isEmpty
                              ? AppColors.adminRed.withValues(alpha: 0.45)
                              : AppColors.adminRed,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _reasonController.text.trim().isEmpty
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.adminRed
                                        .withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                        ),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Report as False',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
