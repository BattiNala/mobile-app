import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/citizen_dashboard/controllers/citizen_dashboard_notifier.dart';
import 'package:batti_nala/features/shared/issue/models/issue_model.dart';
import 'package:batti_nala/features/user-issue/view/widgets/issue_card_widget.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:batti_nala/features/profile/view/profile_screen.dart';
import 'package:batti_nala/features/shared/widgets/app_bottom_nav.dart';
import 'package:batti_nala/features/shared/widgets/empty_state_widget.dart';
import 'package:batti_nala/features/shared/widgets/logout_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class CitizenDashboardView extends ConsumerStatefulWidget {
  const CitizenDashboardView({super.key});

  @override
  ConsumerState<CitizenDashboardView> createState() =>
      _CitizenDashboardViewState();
}

class _CitizenDashboardViewState extends ConsumerState<CitizenDashboardView> {
  int _currentIndex = 0;
  String _searchQuery = '';
  String _statusFilter = 'all';
  final _searchController = SearchController();

  static const _filters = [
    ('all', 'All'),
    ('open', 'Open'),
    ('in_progress', 'In Progress'),
    ('resolved', 'Resolved'),
  ];

  List<IssueModel> _filteredIssues(List<IssueModel> issues) {
    var result = issues.toList();
    switch (_statusFilter) {
      case 'open':
        result = result
            .where((i) =>
                i.status.toUpperCase() == 'OPEN' ||
                i.status.toUpperCase() == 'PENDING_VERIFICATION')
            .toList();
      case 'in_progress':
        result = result
            .where((i) => i.status.toUpperCase() == 'IN_PROGRESS')
            .toList();
      case 'resolved':
        result = result
            .where((i) => i.status.toUpperCase() == 'RESOLVED')
            .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((i) =>
              i.issueType.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q) ||
              i.issueLabel.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reports = ref.watch(dashboardProvider);
    final dashboardController = ref.read(dashboardProvider.notifier);

    final profileState = ref.watch(profileNotifierProvider);
    final profileController = ref.read(profileNotifierProvider.notifier);
    final citizenProfile = profileState.citizenProfile;

    if (profileState.errorMessage != null && reports.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            onPressed: () => showLogoutSheet(context, ref),
          ),
          centerTitle: true,
          title: const Text('Dashboard'),
          backgroundColor: AppColors.primaryBlue900,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Connection Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue900,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Could not connect to the server. Please check your internet connection or ensure the backend is running.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await dashboardController.refreshReports();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (profileState.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            /// HEADER PLACEHOLDER
            Shimmer.fromColors(
              baseColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              highlightColor: AppColors.primaryBlue.withValues(alpha: 0.5),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue900.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue900.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// REPORT LIST PLACEHOLDERS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: 5,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                      highlightColor: Colors.white.withValues(alpha: 0.3),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        color: AppColors.primaryBlue,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 74,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withValues(
                                          alpha: 0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 100,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withValues(
                                          alpha: 0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    final navItems = [
      const NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      const NavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              heroTag: 'citizen_dashboard_add_issue',
              backgroundColor: Colors.red.shade600,
              onPressed: () async {
                await context.push('/issue-create');
                await dashboardController.refreshReports();
              },
              child: const Icon(Icons.add, size: 30, color: Colors.white),
            )
          : null,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: navItems,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkScreenGradient
              : AppColors.screenGradient,
        ),
        child: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Dashboard
          RefreshIndicator(
        onRefresh: () async {
          // Refresh both dashboard reports and profile
          await Future.wait([
            dashboardController.refreshReports(),
            profileController.fetchProfile('citizen'),
          ]);
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// User Info Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome Back,',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      citizenProfile?.name ?? 'User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            /// Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    'Pending',
                                    dashboardController.pendingCount,
                                    Icons.access_time,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _statCard(
                                    'Resolved',
                                    dashboardController.resolvedCount,
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// REPORT LIST
            SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Search bar
                    SearchBar(
                      controller: _searchController,
                      hintText: 'Search your reports...',
                      leading: const Icon(Icons.search_rounded, size: 20),
                      trailing: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            }),
                          ),
                      ],
                      onChanged: (v) => setState(() => _searchQuery = v),
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStatePropertyAll(
                        isDark
                            ? AppColors.darkSurface
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      shape: const WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 14),
                      ),
                      textStyle: WidgetStatePropertyAll(
                        TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextMain
                              : AppColors.textMain,
                        ),
                      ),
                      hintStyle: WidgetStatePropertyAll(
                        TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map(
                          ((String, String) f) {
                            final isSelected = _statusFilter == f.$1;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f.$2),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _statusFilter = f.$1),
                                backgroundColor: isDark
                                    ? AppColors.darkSurface2
                                    : const Color(0xFFEEF2FF),
                                selectedColor: AppColors.primaryBlue
                                    .withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                          .withValues(alpha: 0.5)
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.border),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                showCheckmark: false,
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_filteredIssues(reports).isEmpty)
                      EmptyStateWidget(
                        title: _searchQuery.isNotEmpty ||
                                _statusFilter != 'all'
                            ? 'No Matches'
                            : 'No Reports Yet',
                        subtitle: _searchQuery.isNotEmpty ||
                                _statusFilter != 'all'
                            ? 'Try a different search or filter.'
                            : 'Tap + to report a civic issue.',
                        icon: _searchQuery.isNotEmpty ||
                                _statusFilter != 'all'
                            ? Icons.search_off_rounded
                            : Icons.assignment_outlined,
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _filteredIssues(reports).length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 11),
                        itemBuilder: (context, index) {
                          final report = _filteredIssues(reports)[index];
                          return InkWell(
                            onTap: () async {
                              await context.push(
                                  '/issue-detail/${report.issueLabel}');
                              dashboardController.refreshReports();
                            },
                            child: IssueCardWidget(issue: report),
                          );
                        },
                      ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),

          // Tab 1: Profile
          const ProfileScreen(),
        ],
      ),
      ),
    );
  }

  /// STAT CARD
  Widget _statCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
