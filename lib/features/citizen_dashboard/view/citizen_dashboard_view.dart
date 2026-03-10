import 'package:batti_nala/core/utils/colors.dart';
import 'package:batti_nala/features/citizen_dashboard/controllers/citizen_dashboard_notifier.dart';
import 'package:batti_nala/core/models/issue_model.dart';
import 'package:batti_nala/features/profile/controller/profile_notifer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class CitizenDashboardView extends ConsumerWidget {
  const CitizenDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(dashboardProvider);
    final dashboardController = ref.read(dashboardProvider.notifier);

    final profileState = ref.watch(profileNotifierProvider);
    final profileController = ref.read(profileNotifierProvider.notifier);
    final citizenProfile = profileState.citizenProfile;

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
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                      highlightColor: Colors.white.withValues(alpha: 0.3),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.primaryBlue,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
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

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade600,
        onPressed: () {},
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh both dashboard reports and profile
          await Future.wait([
            dashboardController.refreshReports(),
            profileController.fetchProfile("citizen"), // fetch by role
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              /// HEADER
              Container(
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
                    /// Welcome row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome Back,",
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
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// Stats
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "Pending",
                            dashboardController.pendingCount,
                            Icons.access_time,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _statCard(
                            "Resolved",
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

              /// REPORT LIST
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Your Reports",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 12),

                    // Show loading if reports not loaded yet
                    if (reports.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          return InkWell(
                            onTap: () {
                              // Navigate to issue details
                            },
                            child: _reportCard(report),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
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

  /// REPORT CARD
  Widget _reportCard(Issue report) {
    final isWater = report.category == "water";
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isWater
                        ? Colors.blue.shade50
                        : Colors.yellow.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isWater ? Icons.water_drop : Icons.flash_on,
                    color: isWater ? Colors.blue : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.description,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.locationName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Text(
                  report.reportedAt,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
