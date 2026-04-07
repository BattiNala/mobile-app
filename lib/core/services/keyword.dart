import 'package:batti_nala/core/services/detection.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class KeywordMatchResult {
  final String? detectedType;
  final double confidence;
  final List<String> matchedKeywords;
  final int totalMatches;
  final double avgPriority;

  KeywordMatchResult({
    this.detectedType,
    required this.confidence,
    required this.matchedKeywords,
    required this.totalMatches,
    required this.avgPriority,
  });

  bool get hasMatch => detectedType != null && confidence > 0.0;
}

class ImprovedKeywordMatcher {
  /// Match labels against keyword dictionary with weighted scoring
  static KeywordMatchResult matchKeywords(
    List<ImageLabel> labels,
    Map<String, List<KeywordEntry>> keywordDict,
  ) {
    final typeScores = <String, double>{};
    final typeMatches = <String, List<String>>{};
    final typePriorities = <String, List<int>>{};

    for (var label in labels) {
      final text = label.label.toLowerCase().trim();
      final labelConfidence = label.confidence;

      // Try to match against all types
      for (var entry in keywordDict.entries) {
        final type = entry.key;
        final keywords = entry.value;

        for (var keywordEntry in keywords) {
          final keyword = keywordEntry.keyword.toLowerCase();
          final priority = keywordEntry.priority;
          final exactMatch = keywordEntry.exactMatch;

          bool matched = false;

          if (exactMatch) {
            // Exact match required
            matched = text == keyword;
          } else {
            // Partial match OK
            matched = text.contains(keyword);
          }

          if (matched) {
            // Calculate match score
            final matchScore = _calculateMatchScore(
              labelConfidence,
              priority,
              exactMatch,
              text == keyword, // is it an exact word match?
            );

            // Accumulate score for this type
            typeScores[type] = (typeScores[type] ?? 0.0) + matchScore;

            // Track matched keywords
            typeMatches[type] = typeMatches[type] ?? [];
            if (!typeMatches[type]!.contains(keyword)) {
              typeMatches[type]!.add(keyword);
            }

            // Track priorities
            typePriorities[type] = typePriorities[type] ?? [];
            typePriorities[type]!.add(priority);

            print(
              '  Matched "$keyword" in "$text" -> $type '
              '(score: ${matchScore.toStringAsFixed(2)})',
            );
          }
        }
      }
    }

    if (typeScores.isEmpty) {
      return KeywordMatchResult(
        confidence: 0.0,
        matchedKeywords: [],
        totalMatches: 0,
        avgPriority: 0.0,
      );
    }

    // Normalize scores based on number of matches
    final normalizedScores = <String, double>{};
    for (var entry in typeScores.entries) {
      final type = entry.key;
      final rawScore = entry.value;
      final matchCount = typeMatches[type]!.length;

      // Boost for multiple different keyword matches
      double multiMatchBoost = 0.0;
      if (matchCount >= 3) {
        multiMatchBoost = DetectionConfig.multiKeywordBoost * 1.5;
      } else if (matchCount >= 2) {
        multiMatchBoost = DetectionConfig.multiKeywordBoost;
      }

      normalizedScores[type] = (rawScore + multiMatchBoost).clamp(0.0, 1.0);
    }

    // Find best match
    final sorted = normalizedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestType = sorted.first.key;
    final bestConfidence = sorted.first.value;
    final keywords = typeMatches[bestType]!;
    final priorities = typePriorities[bestType]!;
    final avgPriority = priorities.reduce((a, b) => a + b) / priorities.length;

    print(
      '  Best match: $bestType (conf: ${bestConfidence.toStringAsFixed(2)}, '
      'matches: ${keywords.length}, avgPriority: ${avgPriority.toStringAsFixed(1)})',
    );

    return KeywordMatchResult(
      detectedType: bestType,
      confidence: bestConfidence,
      matchedKeywords: keywords,
      totalMatches: keywords.length,
      avgPriority: avgPriority,
    );
  }

  /// Calculate weighted match score
  static double _calculateMatchScore(
    double labelConfidence,
    int priority,
    bool exactMatchRequired,
    bool isExactWordMatch,
  ) {
    // Base score from ML Kit confidence
    double score = labelConfidence * 0.6; // Start with 60% of label confidence

    // Priority weight (0-10 scale, normalize to 0.0-0.4)
    final priorityWeight = (priority / 10.0) * 0.4;
    score += priorityWeight;

    // Exact match bonus
    if (exactMatchRequired && isExactWordMatch) {
      score += DetectionConfig.exactMatchBoost;
    } else if (!exactMatchRequired && isExactWordMatch) {
      score += DetectionConfig.partialMatchBoost;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Check for rejection keywords
  static KeywordMatchResult checkRejection(List<ImageLabel> labels) {
    final rejectionKeywords = DetectionKeywords.rejection;
    final matches = <String>[];
    double maxConfidence = 0.0;

    for (var label in labels) {
      final text = label.label.toLowerCase().trim();
      final labelConfidence = label.confidence;

      for (var keywordEntry in rejectionKeywords) {
        final keyword = keywordEntry.keyword.toLowerCase();

        if (text.contains(keyword)) {
          // Only reject if confidence is high enough
          if (labelConfidence >= DetectionConfig.rejectionMinConfidence) {
            matches.add(keyword);
            if (labelConfidence > maxConfidence) {
              maxConfidence = labelConfidence;
            }
            print(
              '  REJECTION: Found "$keyword" in "$text" '
              '(conf: ${labelConfidence.toStringAsFixed(2)})',
            );
          } else {
            print(
              '  Ignored low-conf rejection: "$keyword" in "$text" '
              '(conf: ${labelConfidence.toStringAsFixed(2)})',
            );
          }
        }
      }
    }

    return KeywordMatchResult(
      detectedType: matches.isNotEmpty ? 'REJECTED' : null,
      confidence: maxConfidence,
      matchedKeywords: matches,
      totalMatches: matches.length,
      avgPriority: 10.0, // Rejection is highest priority
    );
  }

  /// Check for context keywords that boost confidence
  static double calculateContextBoost(List<ImageLabel> labels) {
    final contextKeywords = DetectionKeywords.positiveContext;
    int matchedSignals = 0;
    final matches = <String>[];

    for (var label in labels) {
      final text = label.label.toLowerCase().trim();

      for (var keywordEntry in contextKeywords) {
        final keyword = keywordEntry.keyword.toLowerCase();

        if (text.contains(keyword)) {
          matchedSignals++;
          matches.add(keyword);
          break; // Only count each label once
        }
      }
    }

    final boost = (matchedSignals * DetectionConfig.contextBoostPerSignal)
        .clamp(0.0, DetectionConfig.maxContextBoost);

    if (boost > 0) {
      print('  Context boost: +${boost.toStringAsFixed(2)} from $matches');
    }

    return boost;
  }

  /// Assess priority level
  static String assessPriority(List<ImageLabel> labels) {
    final priorityDict = DetectionKeywords.priority;

    // Check HIGH priority first
    for (var label in labels) {
      final text = label.label.toLowerCase().trim();

      for (var keywordEntry in priorityDict['HIGH']!) {
        if (text.contains(keywordEntry.keyword.toLowerCase())) {
          print('  Priority: HIGH (keyword: ${keywordEntry.keyword})');
          return 'HIGH';
        }
      }
    }

    // Then check NORMAL priority
    for (var label in labels) {
      final text = label.label.toLowerCase().trim();

      for (var keywordEntry in priorityDict['NORMAL']!) {
        if (text.contains(keywordEntry.keyword.toLowerCase())) {
          print('  Priority: NORMAL (keyword: ${keywordEntry.keyword})');
          return 'NORMAL';
        }
      }
    }

    print('  Priority: LOW (no priority keywords found)');
    return 'LOW';
  }
}
