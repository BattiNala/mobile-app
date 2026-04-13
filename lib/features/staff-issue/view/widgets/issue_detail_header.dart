import 'package:flutter/material.dart';
import 'package:batti_nala/core/constants/colors.dart';

class IssueDetailHeader extends StatelessWidget {
  final String issueLabel;
  final String issueType;
  final String? rejectedReason;
  final VoidCallback? onReportFalse;

  const IssueDetailHeader({
    super.key,
    required this.issueLabel,
    required this.issueType,
    this.rejectedReason,
    this.onReportFalse,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
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
      actions: [
        if (onReportFalse != null)
          IconButton(
            icon: const Icon(Icons.outlined_flag, color: Colors.white),
            tooltip: 'Report False',
            onPressed: onReportFalse,
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(color: AppColors.primaryBlue900),
          child: Stack(
            children: [
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
                        issueLabel,
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
                      issueType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (rejectedReason != null && rejectedReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Flagged: $rejectedReason',
                        style: TextStyle(
                          color: Colors.red[200],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
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
}
