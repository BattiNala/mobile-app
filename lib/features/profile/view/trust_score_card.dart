import 'package:flutter/material.dart';

class TrustScoreCard extends StatelessWidget {
  final int score;

  const TrustScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (score >= 80) return const Color(0xFF059669);
      if (score >= 60) return const Color(0xFFF59E0B);
      return const Color(0xFFDC2626);
    }

    final color = getColor();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trust Score', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score / 100,
            color: color,
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}
