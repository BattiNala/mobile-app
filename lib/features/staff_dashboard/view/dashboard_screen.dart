import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/staff_dashboard/controller/employee_dashboard_notifier.dart';
import 'package:batti_nala/features/issue_report/models/issue_model.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/issue_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class StaffDashboard extends ConsumerWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(employeeDashboardProvider);
    final dashboardController = ref.read(employeeDashboardProvider.notifier);
    final profileState = ref.watch(profileNotifierProvider);
    final employee = profileState.employeeProfile;

    if (employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeIssues = issues
        .where(
          (i) =>
              i.status.toUpperCase() != 'RESOLVED' &&
              i.status.toUpperCase() != 'CLOSED',
        )
        .toList();
    final resolvedIssues = issues
        .where((i) => i.status.toUpperCase() == 'RESOLVED')
        .toList();

    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    final bool isSmallPhone = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: RefreshIndicator(
        onRefresh: () async {
          await dashboardController.refreshReports();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            /// HEADER
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.welcomeGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      /// Nepal Top Border
                      Container(
                        height: 4,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue900,
                              AppColors.adminRed,
                              Color(0xFF006B3F),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(isTablet ? 24 : 16),

                        child: Column(
                          children: [
                            /// USER INFO
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Municipal Staff',
                                        style: TextStyle(
                                          fontSize: isSmallPhone ? 11 : 12,
                                          color: Colors.blue[200],
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        employee.name,
                                        style: TextStyle(
                                          fontSize: isTablet ? 24 : 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        '${employee.department.toUpperCase()} DEPARTMENT',
                                        style: TextStyle(
                                          fontSize: isSmallPhone ? 10 : 12,
                                          color: Colors.blue[200],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                GestureDetector(
                                  onTap: () => context.push('/profile'),
                                  child: Container(
                                    width: isTablet ? 48 : 40,
                                    height: isTablet ? 48 : 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: .2,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      FontAwesomeIcons.user,
                                      color: Colors.white,
                                      size: isTablet ? 20 : 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            /// STATS CARD
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .1),
                                ),
                              ),

                              child: Padding(
                                padding: EdgeInsets.all(isTablet ? 20 : 16),

                                child: Column(
                                  children: [
                                    /// TOTAL ISSUES
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Issues',
                                          style: TextStyle(
                                            fontSize: isSmallPhone ? 11 : 13,
                                            color: Colors.blue[100],
                                          ),
                                        ),
                                        Text(
                                          issues.length.toString(),
                                          style: TextStyle(
                                            fontSize: isTablet ? 32 : 28,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        _statItem(
                                          label: 'Pending',
                                          count:
                                              dashboardController.pendingCount,
                                          color: Colors.orange[300]!,
                                          isTablet: isTablet,
                                        ),

                                        _statItem(
                                          label: 'In Progress',
                                          count: dashboardController
                                              .inProgressCount,
                                          color: Colors.blue[300]!,
                                          isTablet: isTablet,
                                        ),

                                        _statItem(
                                          label: 'Resolved',
                                          count:
                                              dashboardController.resolvedCount,
                                          color: Colors.green[300]!,
                                          isTablet: isTablet,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// ACTIVE ISSUES
            SliverPadding(
              padding: EdgeInsets.all(isTablet ? 24 : 16),

              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Text(
                        'Active Issues',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ...activeIssues.asMap().entries.map((entry) {
                    final index = entry.key;
                    final issue = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _issueCard(
                        issue: issue,
                        index: index + 1,
                        onTap: () => context.push(
                          '/employee-issue-detail/${issue.issueLabel}',
                        ),
                        isTablet: isTablet,
                      ),
                    );
                  }),

                  if (activeIssues.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 64.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No reports found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (resolvedIssues.isNotEmpty) ...[
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Text(
                          'Recently Resolved',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: Colors.green.withValues(alpha: .5),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ...resolvedIssues.map((issue) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _issueCard(
                          issue: issue,
                          isResolved: true,
                          onTap: () => context.push(
                            '/employee-issue-detail/${issue.issueLabel}',
                          ),
                          isTablet: isTablet,
                        ),
                      );
                    }),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem({
    required String label,
    required int count,
    required Color color,
    required bool isTablet,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                color: Colors.blue[200],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _issueCard({
    required IssueModel issue,
    required VoidCallback onTap,
    int? index,
    bool isResolved = false,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: IssueCardWidget(issue: issue),
    );
  }
}
