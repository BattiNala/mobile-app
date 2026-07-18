import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/auth/controllers/auth_notifier.dart';
import 'package:batti_nala/features/auth/controllers/biometric_notifier.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:batti_nala/features/profile/view/profile_avatar.dart';
import 'package:batti_nala/features/profile/view/profile_info_section.dart';
import 'package:batti_nala/features/shared/issue/models/issue_model.dart';
import 'package:batti_nala/features/shared/widgets/action_button.dart';
import 'package:batti_nala/features/shared/widgets/biometric_login_card.dart';
import 'package:batti_nala/features/shared/widgets/biometric_setup_sheet.dart';
import 'package:batti_nala/features/shared/widgets/empty_state_widget.dart';
import 'package:batti_nala/features/shared/widgets/logout_confirm_sheet.dart';
import 'package:batti_nala/features/staff_dashboard/controller/employee_dashboard_notifier.dart';
import 'package:batti_nala/features/user-issue/view/widgets/issue_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StaffDashboard extends ConsumerStatefulWidget {
  const StaffDashboard({super.key});

  @override
  ConsumerState<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends ConsumerState<StaffDashboard>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
  String _searchQuery = '';
  String _statusFilter = 'all';
  final _searchController = SearchController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final email = ref.read(authNotifierProvider).email ?? '';
      if (email.isNotEmpty) {
        await ref.read(biometricNotifierProvider.notifier).verifyForUser(email);
      }
      if (!mounted) return;
      if (ref.read(biometricNotifierProvider).shouldPromptSetup) {
        _showBiometricSetupDialog();
      }
    });
  }

  void _showBiometricSetupDialog() {
    ref.read(biometricNotifierProvider.notifier).dismissSetupPrompt();
    final username = ref.read(authNotifierProvider).email ?? '';
    showBiometricSetupSheet(context, ref, username);
  }

  static const _filters = [
    ('all', 'All'),
    ('active', 'Active'),
    ('in_progress', 'In Progress'),
    ('resolved', 'Resolved'),
  ];

  List<IssueModel> _filteredIssues(List<IssueModel> issues) {
    var result = issues.toList();

    switch (_statusFilter) {
      case 'active':
        result = result
            .where(
              (i) =>
                  i.status.toUpperCase() == 'OPEN' ||
                  i.status.toUpperCase() == 'PENDING_VERIFICATION',
            )
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
          .where(
            (i) =>
                i.issueType.toLowerCase().contains(q) ||
                i.description.toLowerCase().contains(q) ||
                i.issueLabel.toLowerCase().contains(q),
          )
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
    ref.listen(biometricNotifierProvider.select((s) => s.shouldPromptSetup), (
      _,
      shouldPrompt,
    ) {
      if (shouldPrompt && mounted) _showBiometricSetupDialog();
    });

    final issues = ref.watch(employeeDashboardProvider);
    final dashboardController = ref.read(employeeDashboardProvider.notifier);
    final profileState = ref.watch(profileNotifierProvider);
    final employee = profileState.employeeProfile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      bottomNavigationBar: _BottomNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        isDark: isDark,
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          // ── Tab 0: Home ──────────────────────────────
          RefreshIndicator(
            color: AppColors.primaryBlue,
            onRefresh: () async => dashboardController.refreshReports(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(employee, dashboardController, isDark),
                ),
                SliverSafeArea(
                  top: false,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Search bar
                        SearchBar(
                          controller: _searchController,
                          hintText: 'Search issues...',
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
                              borderRadius: BorderRadius.all(
                                Radius.circular(14),
                              ),
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
                            children: _filters.map(((String, String) f) {
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
                                        ? AppColors.primaryBlue.withValues(
                                            alpha: 0.5,
                                          )
                                        : (isDark
                                              ? AppColors.darkBorder
                                              : AppColors.border),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  showCheckmark: false,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _SectionTitle(title: 'Assigned Issues', isDark: isDark),
                        const SizedBox(height: 14),

                        if (_filteredIssues(issues).isEmpty)
                          EmptyStateWidget(
                            title:
                                _searchQuery.isNotEmpty ||
                                    _statusFilter != 'all'
                                ? 'No Matches'
                                : 'All Clear!',
                            subtitle:
                                _searchQuery.isNotEmpty ||
                                    _statusFilter != 'all'
                                ? 'Try a different search or filter.'
                                : 'No active issues assigned to you right now.',
                            icon:
                                _searchQuery.isNotEmpty ||
                                    _statusFilter != 'all'
                                ? Icons.search_off_rounded
                                : Icons.task_alt_rounded,
                          )
                        else
                          ..._filteredIssues(issues).map((issue) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  await context.push(
                                    '/employee-issue-detail/${issue.issueLabel}',
                                  );
                                  dashboardController.refreshReports();
                                },
                                child: IssueCardWidget(issue: issue),
                              ),
                            );
                          }),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab 1: Profile ───────────────────────────
          _StaffProfileTab(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(employee, dashboardController, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.welcomeGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 3,
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${_greeting()},',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              employee.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${employee.department.toUpperCase()} DEPT',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Active',
                          count: dashboardController.pendingCount,
                          icon: Icons.timelapse_rounded,
                          color: const Color(0xFFFB923C),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'In Progress',
                          count: dashboardController.inProgressCount,
                          icon: Icons.published_with_changes_rounded,
                          color: const Color(0xFF60A5FA),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Resolved',
                          count: dashboardController.resolvedCount,
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF34D399),
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
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ─── Staff Profile Tab ────────────────────────────────────────────────────────

class _StaffProfileTab extends ConsumerWidget {
  final bool isDark;
  const _StaffProfileTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final bioState = ref.watch(biometricNotifierProvider);
    final user = authState.user;
    final employee = profileState.employeeProfile;
    final name = employee?.name ?? 'Staff';

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            decoration: const BoxDecoration(
              gradient: AppColors.welcomeGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    height: 3,
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
                  const SizedBox(height: 20),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverSafeArea(
          top: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (user != null)
                  ProfileAvatarCard(name: name, role: user.role),
                const SizedBox(height: 20),
                if (employee != null) ProfileInfoSection(employee: employee),

                if (bioState.isAvailable) ...[
                  const SizedBox(height: 20),
                  const BiometricLoginCard(),
                ],

                const SizedBox(height: 20),
                ActionButton(
                  label: 'Logout',
                  backgroundColor: AppColors.adminRed,
                  onPressed: () => _showLogoutDialog(context, ref),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) =>
      showLogoutSheet(context, ref);
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMain : AppColors.textMain,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom navigation ────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryBlue.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected
                              ? AppColors.primaryBlue
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMuted),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? AppColors.primaryBlue
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMuted),
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
