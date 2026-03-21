import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/staff_dashboard/controller/staff_dashboard_controller.dart';
import 'package:batti_nala/core/models/issue_model.dart';
import 'package:batti_nala/features/staff_dashboard/model/staff_model.dart';
import 'package:batti_nala/features/staff_dashboard/view/status_badge_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StaffDashboard extends ConsumerWidget {
  final Staff staff;
  final VoidCallback onViewMap;
  final Function(Issue) onViewIssue;
  final VoidCallback onNavigateToProfile;

  const StaffDashboard({
    super.key,
    required this.staff,
    required this.onViewMap,
    required this.onViewIssue,
    required this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(staffDashboardProvider.notifier);

    final activeIssues = controller.activeIssues;
    final resolvedIssues = controller.resolvedIssues;

    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    final bool isSmallPhone = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: CustomScrollView(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      staff.name,
                                      style: TextStyle(
                                        fontSize: isTablet ? 24 : 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 2),

                                    Text(
                                      staff.department,
                                      style: TextStyle(
                                        fontSize: isSmallPhone ? 10 : 12,
                                        color: Colors.blue[200],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              GestureDetector(
                                onTap: onNavigateToProfile,
                                child: Container(
                                  width: isTablet ? 48 : 40,
                                  height: isTablet ? 48 : 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: .2),
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
                                        controller.totalIssues.toString(),
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
                                        count: controller.pendingCount,
                                        color: Colors.orange[300]!,
                                        isTablet: isTablet,
                                      ),

                                      _statItem(
                                        label: 'In Progress',
                                        count: controller.inProgressCount,
                                        color: Colors.blue[300]!,
                                        isTablet: isTablet,
                                      ),

                                      _statItem(
                                        label: 'Resolved',
                                        count: controller.resolvedCount,
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
                Text(
                  'Active Issues',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
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
                      onTap: () => onViewIssue(issue),
                      isTablet: isTablet,
                    ),
                  );
                }),

                if (activeIssues.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No active issues')),
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
                        onTap: () => onViewIssue(issue),
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
    required Issue issue,
    required VoidCallback onTap,
    int? index,
    bool isResolved = false,
    required bool isTablet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  issue.category == IssueCategory.water
                      ? FontAwesomeIcons.droplet
                      : FontAwesomeIcons.bolt,
                  color: Colors.blue,
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(issue.description),
                      const SizedBox(height: 4),
                      Text(
                        issue.locationName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: issue.status),

                Text(
                  isResolved ? issue.reportedAt : 'by ${issue.reportedBy}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
