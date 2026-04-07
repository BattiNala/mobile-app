import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/core/widgets/loading_indicator.dart';
import 'package:batti_nala/features/issue_report/controllers/issue_detail_notifier.dart';
import 'package:batti_nala/features/citizen_dashboard/view/widgets/issue_location_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class IssueDetailView extends ConsumerWidget {
  final String issueLabel;

  const IssueDetailView({super.key, required this.issueLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(issueDetailProvider(issueLabel));

    return Scaffold(
      backgroundColor: Colors.white,
      body: state.isLoading
          ? const LoadingIndicator()
          : state.errorMessage != null
          ? Center(child: Text(state.errorMessage!))
          : state.issue == null
          ? const Center(child: Text('Issue not found'))
          : _buildContent(context, state.issue!),
    );
  }

  Widget _buildContent(BuildContext context, var issue) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        /// MODERN BRANDED HEADER
        SliverAppBar(
          expandedHeight: 170.0,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primaryBlue900,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(color: AppColors.primaryBlue900),
              child: Stack(
                children: [
                  // // Decorative Circles for Brand Vibe
                  Positioned(
                    right: -50,
                    top: -20,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            issue.issueLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          issue.issueType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
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

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual Status Bar
              _buildStatusBar(issue.status),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority Row
                    Row(
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          color: _getPriorityColor(issue.issuePriority),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${issue.issuePriority} Priority'.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: _getPriorityColor(issue.issuePriority),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Description Section
                    const _SectionHeading(title: 'What Happened?'),
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

                    // Location integrated snippet
                    const _SectionHeading(title: 'Where?'),
                    const SizedBox(height: 16),
                    IssueLocationCard(
                      location: issue.issueLocation,
                      latitude: issue.latitude,
                      longitude: issue.longitude,
                    ),

                    const SizedBox(height: 40),

                    // Attachments Grid
                    if (issue.attachments.isNotEmpty) ...[
                      const _SectionHeading(title: 'Evidence & Photos'),
                      const SizedBox(height: 16),
                      _buildImageGallery(issue.attachments),
                      const SizedBox(height: 40),
                    ],

                    // Footer with meta-info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildMetaRow(
                            Icons.history_toggle_off_rounded,
                            'Submitted on',
                            _formatDay(issue.createdAt),
                          ),
                          if (issue.assignedTo != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Colors.white),
                            ),
                            _buildMetaRow(
                              Icons.person_pin_rounded,
                              issue.status.toUpperCase() == 'RESOLVED'
                                  ? 'Resolved by'
                                  : 'Handling by',
                              issue.assignedTo!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(String status) {
    final color = _getStatusColor(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getStatusIcon(status), color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusLabel(status).toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _getStatusDescription(status),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> urls) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CachedNetworkImage(
            imageUrl: urls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.white,
              child: Container(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label   ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }

  // Refined Color Helpers
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return AppColors.adminRed;
      case 'IN_PROGRESS':
        return const Color(0xFF3B82F6);
      case 'ASSIGNED':
        return const Color(0xFF8B5CF6);
      case 'RESOLVED':
        return const Color(0xFF10B981);
      default:
        return AppColors.textMuted;
    }
  }

  Color _getPriorityColor(String p) {
    return p.toUpperCase() == 'HIGH'
        ? AppColors.adminRed
        : AppColors.primaryBlue;
  }

  IconData _getStatusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'open':
        return Icons.bolt_rounded;
      case 'in_progress':
        return Icons.published_with_changes_rounded;
      case 'assigned':
        return Icons.verified_user_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getStatusLabel(String s) => s.replaceAll('_', ' ');

  String _getStatusDescription(String s) {
    switch (s.toLowerCase()) {
      case 'open':
        return 'Reported and waiting for review.';
      case 'assigned':
        return 'Technician is taking ownership.';
      case 'in_progress':
        return 'Work is currently being executed.';
      case 'resolved':
        return 'Verified as fixed by municipality.';
      default:
        return 'No status updates yet.';
    }
  }

  String _formatDay(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.textMain,
      ),
    );
  }
}
