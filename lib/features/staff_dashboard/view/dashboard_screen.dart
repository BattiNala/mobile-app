import 'package:batti_nala/core/utils/colors.dart';
import 'package:batti_nala/features/staff_dashboard/model/issue_model.dart';
import 'package:batti_nala/features/staff_dashboard/model/staff_model.dart';
import 'package:batti_nala/features/staff_dashboard/view/status_badge_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Example usage
Staff currentUser = Staff(
  name: 'John Doe',
  department: 'Water Supply Department',
);

// Mock data
final List<Issue> mockIssues = [
  Issue(
    id: '1',
    category: IssueCategory.water,
    description: 'Water leak on main street near temple',
    locationName: 'Thamel, Kathmandu',
    status: IssueStatus.inProgress,
    reportedBy: 'Ram Sharma',
    reportedAt: '2026-01-12 14:30',
  ),
  Issue(
    id: '2',
    category: IssueCategory.electricity,
    description: 'Street light not working',
    locationName: 'Durbarmarg, Kathmandu',
    status: IssueStatus.pending,
    reportedBy: 'Hari Bahadur',
    reportedAt: '2026-01-12 09:15',
  ),
  Issue(
    id: '3',
    category: IssueCategory.water,
    description: 'Empty water tank in neighborhood',
    locationName: 'Patan Dhoka, Lalitpur',
    status: IssueStatus.pending,
    reportedBy: 'Sita Devi',
    reportedAt: '2026-01-11 16:45',
  ),
  Issue(
    id: '4',
    category: IssueCategory.electricity,
    description: 'Power outage in residential area',
    locationName: 'Jawalakhel, Lalitpur',
    status: IssueStatus.pending,
    reportedBy: 'Krishna Prasad',
    reportedAt: '2026-01-11 11:20',
  ),
  Issue(
    id: '5',
    category: IssueCategory.water,
    description: 'Broken water pipe',
    locationName: 'Maitighar, Kathmandu',
    status: IssueStatus.resolved,
    reportedBy: 'Maya Gurung',
    reportedAt: '2026-01-10 08:00',
  ),
];

// Main StaffDashboard Widget
class StaffDashboard extends StatefulWidget {
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
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  late List<Issue> activeIssues;
  late List<Issue> resolvedIssues;

  @override
  void initState() {
    super.initState();
    activeIssues = mockIssues
        .where((i) => i.status != IssueStatus.resolved)
        .toList();
    resolvedIssues = mockIssues
        .where((i) => i.status == IssueStatus.resolved)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;
    final bool isSmallPhone = size.width < 360;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header Sliver
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
                    // Nepal Color Decorative Top Border
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

                    // Header Content
                    Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: Column(
                        children: [
                          // User Info and Profile Button
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.staff.name,
                                      style: TextStyle(
                                        fontSize: isTablet ? 24 : 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.staff.department,
                                      style: TextStyle(
                                        fontSize: isSmallPhone ? 10 : 12,
                                        color: Colors.blue[200],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: widget.onNavigateToProfile,
                                child: Container(
                                  width: isTablet ? 48 : 40,
                                  height: isTablet ? 48 : 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
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

                          // Summary Stats Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isTablet ? 20 : 16),
                              child: Column(
                                children: [
                                  // Total Issues
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
                                        '${mockIssues.length}',
                                        style: TextStyle(
                                          fontSize: isTablet ? 32 : 28,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Stats Grid
                                  Row(
                                    children: [
                                      _buildStatItem(
                                        context,
                                        label: 'Pending',
                                        count: mockIssues
                                            .where(
                                              (i) =>
                                                  i.status ==
                                                  IssueStatus.pending,
                                            )
                                            .length,
                                        color: Colors.orange[300]!,
                                        isTablet: isTablet,
                                      ),
                                      _buildStatItem(
                                        context,
                                        label: 'In Progress',
                                        count: mockIssues
                                            .where(
                                              (i) =>
                                                  i.status ==
                                                  IssueStatus.inProgress,
                                            )
                                            .length,
                                        color: Colors.blue[300]!,
                                        isTablet: isTablet,
                                      ),
                                      _buildStatItem(
                                        context,
                                        label: 'Resolved',
                                        count: mockIssues
                                            .where(
                                              (i) =>
                                                  i.status ==
                                                  IssueStatus.resolved,
                                            )
                                            .length,
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

          // Active Issues Section
          SliverPadding(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header with Route Optimized Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Issues',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Active Issues List
                ...activeIssues.asMap().entries.map((entry) {
                  final index = entry.key;
                  final issue = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildIssueCard(
                      context,
                      issue: issue,
                      index: index + 1,
                      onTap: () => widget.onViewIssue(issue),
                      isTablet: isTablet,
                    ),
                  );
                }),

                if (activeIssues.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No active issues',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ),
                  ),

                // Resolved Section
                if (resolvedIssues.isNotEmpty) ...[
                  const SizedBox(height: 32),

                  // Resolved Header
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
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Resolved Issues List
                  ...resolvedIssues.map((issue) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildIssueCard(
                        context,
                        issue: issue,
                        isResolved: true,
                        onTap: () => widget.onViewIssue(issue),
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

  Widget _buildStatItem(
    BuildContext context, {
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
          color: Colors.white.withValues(alpha: 0.05),
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

  Widget _buildIssueCard(
    BuildContext context, {
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
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1e3a8a), Color(0xFF1e40af)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Row(
                    children: [
                      // Category Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: issue.category == IssueCategory.water
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFe6f2ff),
                                    Color(0xFFb8d9ff),
                                  ],
                                )
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFfff9e6),
                                    Color(0xFFffe6b8),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: issue.category == IssueCategory.water
                                ? Colors.blue[200]!
                                : Colors.yellow[200]!,
                          ),
                        ),
                        child: Icon(
                          issue.category == IssueCategory.water
                              ? FontAwesomeIcons.droplet
                              : FontAwesomeIcons.bolt,
                          color: issue.category == IssueCategory.water
                              ? Colors.blue[600]
                              : Colors.yellow[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.description,
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[900],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              issue.locationName,
                              style: TextStyle(
                                fontSize: isTablet ? 13 : 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: issue.status),
                Text(
                  isResolved ? issue.reportedAt : 'by ${issue.reportedBy}',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
