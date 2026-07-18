import 'dart:ui';

import 'package:batti_nala/core/constants/colors.dart';
import 'package:batti_nala/features/shared/widgets/loading_indicator.dart';
import 'package:batti_nala/features/user-issue/controllers/issue_detail_notifier.dart';
import 'package:batti_nala/features/shared/widgets/issue_location_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class IssueDetailView extends ConsumerWidget {
  final String issueLabel;

  const IssueDetailView({super.key, required this.issueLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(issueDetailProvider(issueLabel));
    final notifier = ref.read(issueDetailProvider(issueLabel).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: state.isLoading
          ? const LoadingIndicator()
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!))
              : state.issue == null
                  ? const Center(child: Text('Issue not found'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await notifier.fetchIssueDetail(issueLabel);
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          _buildHeaderSliver(
                            context,
                            issueLabel,
                            state.issue!,
                            isDark,
                          ),
                          SliverSafeArea(
                            top: false,
                            sliver: _buildContentSliver(
                              context,
                              state.issue!,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  SliverAppBar _buildHeaderSliver(
    BuildContext context,
    String issueLabel,
    dynamic issue,
    bool isDark,
  ) {
    final typeLower = issue.issueType.toLowerCase();
    final isElectricity = typeLower.contains('electricity');
    final isSewage =
        typeLower.contains('sewage') || typeLower.contains('drain');
    final accentColor = isElectricity
        ? AppColors.primaryBlue800
        : isSewage
            ? const Color(0xFF059669)
            : AppColors.adminRed;

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryBlue900,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue900,
                AppColors.primaryBlue800,
                accentColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative blurred circles
              Positioned(
                right: -40,
                top: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Glass content at bottom
              Positioned(
                left: 20,
                right: 20,
                bottom: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Issue label pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            issue.issueLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      issue.issueType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
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
  }

  SliverToBoxAdapter _buildContentSliver(
    BuildContext context,
    dynamic issue,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status glass card
            _buildStatusCard(issue.status, isDark, rejectedReason: issue.status.toUpperCase() == 'REJECTED' ? issue.rejectedReason : null),

            const SizedBox(height: 16),

            // Priority + Description glass card
            _glassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(issue.issuePriority)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.flag_rounded,
                          color: _getPriorityColor(issue.issuePriority),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${issue.issuePriority} Priority'.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: _getPriorityColor(issue.issuePriority),
                        ),
                      ),
                    ],
                  ),

                  Divider(
                    height: 28,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.border,
                  ),

                  _SectionHeading(title: 'What Happened?', isDark: isDark),
                  const SizedBox(height: 12),
                  Text(
                    issue.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      height: 1.65,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location glass card
            _glassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeading(title: 'Where?', isDark: isDark),
                  const SizedBox(height: 14),
                  IssueLocationCard(
                    location: issue.issueLocation,
                    latitude: issue.latitude,
                    longitude: issue.longitude,
                  ),
                ],
              ),
            ),

            // Attachments glass card
            if (issue.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _glassCard(
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeading(
                        title: 'Evidence & Photos', isDark: isDark),
                    const SizedBox(height: 14),
                    _buildImageGallery(issue.attachments),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Meta info glass card
            _glassCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildMetaRow(
                    Icons.history_toggle_off_rounded,
                    'Submitted on',
                    _formatDay(issue.createdAt),
                    isDark,
                  ),
                  if (issue.assignedTo != null) ...[
                    Divider(
                      height: 24,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.border,
                    ),
                    _buildMetaRow(
                      Icons.person_pin_rounded,
                      issue.status.toUpperCase() == 'RESOLVED'
                          ? 'Resolved by'
                          : 'Handling by',
                      issue.assignedTo!,
                      isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    String status,
    bool isDark, {
    String? rejectedReason,
  }) {
    final color = _getStatusColor(status);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark
                ? color.withValues(alpha: 0.12)
                : color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(_getStatusIcon(status), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 3),
                    Text(
                      _getStatusDescription(status),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (status.toUpperCase() == 'REJECTED' &&
                        rejectedReason != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: color.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reason:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  rejectedReason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textMain,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openImageViewer(context, urls, index),
          child: Hero(
            tag: 'citizen_img_${urls[index]}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: urls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.white,
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openImageViewer(
      BuildContext context, List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) =>
            _ImageViewer(urls: urls, initialIndex: initialIndex, heroPrefix: 'citizen_img_'),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _buildMetaRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.primaryBlueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.darkTextSecondary : AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$label  ',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMain : AppColors.textMain,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return AppColors.adminRed;
      case 'IN_PROGRESS':
        return const Color(0xFF3B82F6);
      case 'PENDING_VERIFICATION':
        return const Color(0xFFF59E0B);
      case 'ASSIGNED':
        return const Color(0xFF8B5CF6);
      case 'RESOLVED':
        return const Color(0xFF10B981);
      case 'REJECTED':
        return const Color(0xFFEF4444);
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
      case 'pending_verification':
        return Icons.pending_actions_rounded;
      case 'assigned':
        return Icons.verified_user_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getStatusLabel(String s) => s.replaceAll('_', ' ');

  String _getStatusDescription(String s) {
    switch (s.toLowerCase()) {
      case 'open':
        return 'Reported and waiting for review.';
      case 'pending_verification':
        return 'Awaiting verification by staff.';
      case 'assigned':
        return 'Technician is taking ownership.';
      case 'in_progress':
        return 'Work is currently being executed.';
      case 'resolved':
        return 'Verified as fixed by municipality.';
      case 'rejected':
        return 'Issue was rejected after review.';
      default:
        return 'No status updates yet.';
    }
  }

  String _formatDay(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeading({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextMain : AppColors.textMain,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Full-screen image viewer ─────────────────────────────────────────────────

class _ImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String heroPrefix;

  const _ImageViewer({
    required this.urls,
    required this.initialIndex,
    required this.heroPrefix,
  });

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: '${widget.heroPrefix}${widget.urls[index]}',
                    child: CachedNetworkImage(
                      imageUrl: widget.urls[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  padding: EdgeInsets.fromLTRB(
                    8,
                    MediaQuery.of(context).padding.top + 8,
                    16,
                    12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      if (widget.urls.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.urls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Dot indicators
          if (widget.urls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.urls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == i ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
