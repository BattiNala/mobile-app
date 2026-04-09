import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:batti_nala/core/services/ml_kit_service.dart';
import 'package:batti_nala/core/services/detection.dart';
import 'package:batti_nala/core/services/shape_analyzer.dart';
import 'package:batti_nala/core/services/keyword.dart';

enum Category { electrical, sewage, rejected }

enum DetectionTier { mlKit, inference, imageProperties, rejected }

class DetectionResult {
  final Category category;
  final String? specificType; // e.g., "Electric Pole"
  final String priority; // HIGH, NORMAL, LOW
  final double confidence; // 0.0 - 1.0
  final List<String> matchedKeywords;
  final DetectionTier detectionTier; // NEW: Which method detected it
  final String rejectionReason; // Why rejected (if applicable)

  DetectionResult({
    required this.category,
    this.specificType,
    required this.priority,
    required this.confidence,
    required this.matchedKeywords,
    required this.detectionTier,
    this.rejectionReason = '',
  });

  bool get isValid => category != Category.rejected;
}

class ImprovedImageAnalyzer {
  /// Main analysis coordinator following the 3-tier strategy
  static DetectionResult analyze(AIAnalysisResult aiResult, {File? imageFile}) {
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('🔍 IMPROVED MULTI-TIER ANALYSIS');
    debugPrint('═══════════════════════════════════════════════════════════');

    final labels = aiResult.labels;
    final objects = aiResult.objects;

    debugPrint('\n📊 ML Kit Results:');
    debugPrint('  Labels: ${labels.length}');
    debugPrint('  Objects: ${objects.length}');

    // === STEP 1: REJECTION CHECK (SOFT GATE) ===
    debugPrint('\n[STEP 1] Checking for non-infrastructure...');
    final rejectionResult = ImprovedKeywordMatcher.checkRejection(labels);
    if (rejectionResult.hasMatch) {
      debugPrint(
        '  ⚠️ Rejection signals found, but continuing to verify infrastructure first...',
      );
    } else {
      debugPrint('  ✓ No high-confidence rejection keywords found');
    }

    if (_hasHumanSignals(labels)) {
      debugPrint('❌ REJECTED: Human/person image detected');
      return DetectionResult(
        category: Category.rejected,
        priority: 'LOW',
        confidence: 0.0,
        matchedKeywords: const ['human/person'],
        detectionTier: DetectionTier.rejected,
        rejectionReason:
            'Human or portrait image detected. Please upload a sewage or electrical infrastructure photo only.',
      );
    }

    if (_hasFireSmokeSignals(labels)) {
      debugPrint(
        '✅ FIRE/SMOKE DETECTED: Auto-filling electrical with HIGH priority',
      );
      return DetectionResult(
        category: Category.electrical,
        specificType: 'Electricity',
        priority: 'HIGH',
        confidence: 0.95,
        matchedKeywords: const ['fire', 'smoke'],
        detectionTier: DetectionTier.imageProperties,
        rejectionReason: '',
      );
    }

    final robustDecision = _buildRobustDecision(labels, objects, imageFile);
    if (robustDecision != null) {
      return robustDecision;
    }

    if (!_hasInfrastructureSignals(labels, objects, imageFile)) {
      debugPrint('❌ REJECTED: No sewage/electrical infrastructure evidence');
      return DetectionResult(
        category: Category.rejected,
        priority: 'LOW',
        confidence: 0.0,
        matchedKeywords: const [],
        detectionTier: DetectionTier.rejected,
        rejectionReason:
            'No sewage or electrical infrastructure detected. Please upload only sewage or electrical issue photos.',
      );
    }

    // === STEP 2: SHAPE ANALYSIS ===
    debugPrint('\n[STEP 2] Analyzing object shapes...');
    final shapeResults = objects
        .map((obj) => ImprovedShapeAnalyzer.analyzeObject(obj))
        .toList();

    // === TIER 1: ML KIT + SHAPE (Primary) ===
    debugPrint('\n[TIER 1] ML Kit Label + Shape Detection...');
    final tier1Result = _runTier1(labels, shapeResults);

    if (tier1Result != null &&
        tier1Result.confidence >= DetectionConfig.mlKitMinConfidence) {
      debugPrint('✅ TIER 1 SUCCESS');
      return _finalizeResult(
        tier1Result,
        labels,
        imageFile,
        DetectionTier.mlKit,
      );
    }

    debugPrint('⚠️  Tier 1 FAILED: Insufficient confidence, trying Tier 2...');

    // === TIER 2: KEYWORD INFERENCE (Secondary) ===
    debugPrint('\n[TIER 2] Keyword Inference Fallback (STRICT MODE)...');
    final tier2Result = _runTier2(labels, shapeResults);

    if (tier2Result != null &&
        tier2Result.confidence >= DetectionConfig.inferenceMinConfidence) {
      debugPrint('✅ TIER 2 SUCCESS');
      return _finalizeResult(
        tier2Result,
        labels,
        imageFile,
        DetectionTier.inference,
      );
    }

    debugPrint('⚠️  Tier 2 FAILED: Trying Tier 3...');

    // === TIER 3: IMAGE PROPERTIES (Tertiary) ===
    if (imageFile != null) {
      debugPrint('\n[TIER 3] Image Properties Analysis...');
      final tier3Result = _runTier3(imageFile, labels);

      if (tier3Result != null &&
          tier3Result.confidence >=
              DetectionConfig.imagePropertiesMinConfidence) {
        debugPrint('✅ TIER 3 SUCCESS');
        return _finalizeResult(
          tier3Result,
          labels,
          imageFile,
          DetectionTier.imageProperties,
        );
      }
    }

    if (rejectionResult.hasMatch) {
      debugPrint('❌ REJECTED: Non-infrastructure detected');
      return DetectionResult(
        category: Category.rejected,
        priority: 'LOW',
        confidence: 0.0,
        matchedKeywords: rejectionResult.matchedKeywords,
        detectionTier: DetectionTier.rejected,
        rejectionReason:
            'Non-infrastructure detected: ${rejectionResult.matchedKeywords}',
      );
    }

    // === FINAL: ALL TIERS FAILED ===
    debugPrint('\n❌ ALL TIERS FAILED: Cannot detect infrastructure');
    return DetectionResult(
      category: Category.rejected,
      priority: 'LOW',
      confidence: 0.0,
      matchedKeywords: [],
      detectionTier: DetectionTier.rejected,
      rejectionReason: 'Could not detect infrastructure in any tier',
    );
  }

  static _TierResult? _runTier1(
    List<ImageLabel> labels,
    List<ShapeAnalysisResult> shapeResults,
  ) {
    // 1. Detect Electrical
    final elecMatch = ImprovedKeywordMatcher.matchKeywords(
      labels,
      DetectionKeywords.electrical,
    );

    // 2. Detect Sewage
    final sewageMatch = ImprovedKeywordMatcher.matchKeywords(
      labels,
      DetectionKeywords.sewage,
    );

    // Apply shape boosts and context boosts
    final elecScore = _calculateBoostedScore(
      elecMatch,
      shapeResults,
      labels,
      Category.electrical,
    );
    final sewageScore = _calculateBoostedScore(
      sewageMatch,
      shapeResults,
      labels,
      Category.sewage,
    );

    debugPrint(
      '  Final Electrical: ${elecScore.confidence.toStringAsFixed(2)}, '
      'Sewage: ${sewageScore.confidence.toStringAsFixed(2)}',
    );

    if (elecScore.confidence >= sewageScore.confidence &&
        elecScore.confidence > 0) {
      return _TierResult(
        category: Category.electrical,
        type: elecScore.type,
        confidence: elecScore.confidence,
        keywords: elecScore.keywords,
      );
    } else if (sewageScore.confidence > elecScore.confidence) {
      return _TierResult(
        category: Category.sewage,
        type: sewageScore.type,
        confidence: sewageScore.confidence,
        keywords: sewageScore.keywords,
      );
    }

    return null;
  }

  static _TierResult? _runTier2(
    List<ImageLabel> labels,
    List<ShapeAnalysisResult> shapeResults,
  ) {
    // Tier 2 uses the same matcher but might have lower requirements or handle generics differently
    // In our implementation, matchKeywords already handles weighting.
    // The "STRICT MODE" is built into the matchKeywords logic + the Config thresholds.
    return _runTier1(labels, shapeResults);
  }

  static _TierResult? _runTier3(File imageFile, List<ImageLabel> labels) {
    try {
      final bytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Downsample for performance (Plan says 60% faster)
      final thumbnail = img.copyResize(image, width: 200, height: 200);

      final properties = _sampleImageProperties(thumbnail);
      debugPrint('  Properties: $properties');
      final hasElectricalSignals = _hasElectricalSignals(labels);
      final hasSewageSignals = _hasSewageSignals(labels);
      final hasFireSignals = _hasFireSignals(labels);

      String? type;
      Category? category;
      double maxConf = 0.0;
      final keywords = <String>[];

      // Fire Detection
      if (properties['firePercentage']! >
              DetectionConfig.firePercentageThreshold &&
          (hasFireSignals || hasElectricalSignals)) {
        type = 'Electricity';
        category = Category.electrical;
        maxConf =
            properties['firePercentage']! >
                DetectionConfig.emergencyFireThreshold
            ? 0.85
            : 0.70;
        keywords.add('🔥fire_colors_detected');
      }

      // Sewage/water-like surface
      if (category == null &&
          properties['waterLikePercentage']! > 0.10 &&
          (hasSewageSignals || properties['brownPercentage']! > 0.04)) {
        type = 'Sewage';
        category = Category.sewage;
        maxConf = 0.62;
        keywords.add('water_like_surface');
      }

      // Sewage/Brown
      if (category == null &&
          properties['brownPercentage']! >
              DetectionConfig.brownPercentageThreshold &&
          hasSewageSignals) {
        type = 'Sewage';
        category = Category.sewage;
        maxConf = 0.60;
        keywords.add('brown_sewage_corrosion');
      }

      // Electrical contrast (fallback only)
      if (category == null &&
          properties['highContrastPixels']! >
              DetectionConfig.highContrastThreshold &&
          hasElectricalSignals) {
        type = 'Electricity';
        category = Category.electrical;
        maxConf = 0.50;
        keywords.add('high_contrast_structure');
      }

      if (category != null) {
        return _TierResult(
          category: category,
          type: type,
          confidence: maxConf,
          keywords: keywords,
        );
      }
    } catch (e) {
      debugPrint('  ❌ Tier 3 Error: $e');
    }
    return null;
  }

  static bool _hasElectricalSignals(List<ImageLabel> labels) {
    const electricalTokens = [
      'electric',
      'electricity',
      'power',
      'wire',
      'cable',
      'pole',
      'transformer',
      'lamp',
      'light',
      'utility',
      'wires',
    ];

    return labels.any((label) {
      final text = label.label.toLowerCase();
      return electricalTokens.any(text.contains) && label.confidence >= 0.45;
    });
  }

  static bool _hasSewageSignals(List<ImageLabel> labels) {
    const sewageTokens = [
      'sewage',
      'sewer',
      'drain',
      'drainage',
      'manhole',
      'overflow',
      'flood',
      'water',
      'pipe',
      'waste',
    ];

    return labels.any((label) {
      final text = label.label.toLowerCase();
      return sewageTokens.any(text.contains) && label.confidence >= 0.40;
    });
  }

  static bool _hasSewageDirectSignals(List<ImageLabel> labels) {
    const sewageDirectTokens = [
      'sewage',
      'sewer',
      'drain',
      'drainage',
      'manhole',
      'overflow',
      'overflowing',
      'flood',
      'waterlogging',
      'water',
      'leak',
      'pipe',
      'waste',
      'puddle',
      'wet',
    ];

    return labels.any((label) {
      final text = label.label.toLowerCase();
      return sewageDirectTokens.any(text.contains) && label.confidence >= 0.35;
    });
  }

  static bool _hasFireSignals(List<ImageLabel> labels) {
    const fireTokens = ['fire', 'flame', 'smoke', 'burn', 'spark'];

    return labels.any((label) {
      final text = label.label.toLowerCase();
      return fireTokens.any(text.contains) && label.confidence >= 0.40;
    });
  }

  static bool _hasHumanSignals(List<ImageLabel> labels) {
    const humanCoreTokens = [
      'person',
      'people',
      'human',
      'face',
      'selfie',
      'portrait',
      'man',
      'woman',
      'child',
    ];

    const humanAccessoryTokens = [
      'smile',
      'beard',
      'moustache',
      'mustache',
      'eyelash',
      'eyebrow',
      'lip',
      'nose',
      'cheek',
      'jaw',
      'flesh',
      'shirt',
      'jacket',
    ];

    int coreSignals = 0;
    int accessorySignals = 0;
    for (final label in labels) {
      final text = label.label.toLowerCase();
      if (humanCoreTokens.any(text.contains) && label.confidence >= 0.35) {
        coreSignals++;
      }
      if (humanAccessoryTokens.any(text.contains) && label.confidence >= 0.40) {
        accessorySignals++;
      }
    }

    return coreSignals >= 1 || accessorySignals >= 3;
  }

  static bool _hasFireSmokeSignals(List<ImageLabel> labels) {
    const fireSmokeTokens = [
      'fire',
      'smoke',
      'flame',
      'burn',
      'burning',
      'spark',
    ];

    int fireSmokeSignals = 0;
    for (final label in labels) {
      final text = label.label.toLowerCase();
      if (fireSmokeTokens.any(text.contains) && label.confidence >= 0.40) {
        fireSmokeSignals++;
      }
    }

    return fireSmokeSignals >= 1;
  }

  static DetectionResult? _buildRobustDecision(
    List<ImageLabel> labels,
    List<DetectedObject> objects,
    File? imageFile,
  ) {
    final hasSewageDirectSignals = _hasSewageDirectSignals(labels);
    final hasElectricalDirectSignals = _hasElectricalSignals(labels);

    final electricalSignals = <String>[];
    final sewageSignals = <String>[];

    double electricalScore = 0.0;
    double sewageScore = 0.0;

    for (final label in labels) {
      final text = label.label.toLowerCase();
      if (_matchesAny(text, _electricalTokens())) {
        electricalSignals.add(label.label);
        electricalScore += 0.55 * label.confidence;
      }
      if (_matchesAny(text, _sewageTokens())) {
        sewageSignals.add(label.label);
        sewageScore += 0.55 * label.confidence;
      }
    }

    for (final object in objects) {
      final shape = ImprovedShapeAnalyzer.analyzeObject(object).primaryShape;
      if (shape == ShapeType.tall ||
          shape == ShapeType.boxLike ||
          shape == ShapeType.linear) {
        electricalScore += 0.28;
      }
      if (shape == ShapeType.circular || shape == ShapeType.irregular) {
        sewageScore += 0.22;
      }
    }

    if (imageFile != null) {
      try {
        final bytes = imageFile.readAsBytesSync();
        final image = img.decodeImage(bytes);
        if (image != null) {
          final thumbnail = img.copyResize(image, width: 120, height: 120);
          final properties = _sampleImageProperties(thumbnail);
          final firePct = properties['firePercentage']!;
          final brownPct = properties['brownPercentage']!;
          final waterPct = properties['waterLikePercentage']!;
          final contrastPct = properties['highContrastPixels']!;

          electricalScore += (contrastPct * 0.25);
          sewageScore += (brownPct * 0.45) + (waterPct * 0.35);

          if (firePct > 0.08) {
            electricalScore += 0.45;
          }

          if (brownPct > 0.03 || waterPct > 0.05) {
            sewageScore += 0.15;
          }
        }
      } catch (_) {}
    }

    if (hasSewageDirectSignals) {
      final sewageVisualHint =
          imageFile != null && _hasSewageVisualSignals(imageFile);
      if (sewageVisualHint || sewageScore >= 0.35) {
        final overflowOrLeak = sewageSignals.any((signal) {
          final lower = signal.toLowerCase();
          return lower.contains('overflow') ||
              lower.contains('leak') ||
              lower.contains('flood') ||
              lower.contains('drain');
        });

        return DetectionResult(
          category: Category.sewage,
          specificType: 'Sewage',
          priority: overflowOrLeak ? 'HIGH' : 'NORMAL',
          confidence: (0.72 + sewageScore).clamp(0.0, 1.0),
          matchedKeywords: sewageSignals.isEmpty
              ? const ['sewage']
              : sewageSignals,
          detectionTier: DetectionTier.imageProperties,
          rejectionReason: '',
        );
      }
    }

    if (hasElectricalDirectSignals && electricalScore >= 0.45) {
      final highPriority = electricalSignals.any((signal) {
        final lower = signal.toLowerCase();
        return lower.contains('fire') ||
            lower.contains('smoke') ||
            lower.contains('spark') ||
            lower.contains('burn');
      });

      return DetectionResult(
        category: Category.electrical,
        specificType: 'Electricity',
        priority: highPriority
            ? 'HIGH'
            : _priorityFromSignals(
                Category.electrical,
                electricalSignals,
                electricalScore,
              ),
        confidence: electricalScore.clamp(0.0, 1.0),
        matchedKeywords: electricalSignals.isEmpty
            ? const ['electricity']
            : electricalSignals,
        detectionTier: DetectionTier.imageProperties,
        rejectionReason: '',
      );
    }

    if (imageFile != null) {
      try {
        final bytes = imageFile.readAsBytesSync();
        final image = img.decodeImage(bytes);
        if (image != null) {
          final thumbnail = img.copyResize(image, width: 120, height: 120);
          final properties = _sampleImageProperties(thumbnail);
          final waterPct = properties['waterLikePercentage']!;
          final brownPct = properties['brownPercentage']!;
          final contrastPct = properties['highContrastPixels']!;

          final strongSewageVisual =
              (waterPct >= 0.20 && brownPct >= 0.015) ||
              (waterPct >= 0.28) ||
              (brownPct >= 0.04 && contrastPct >= 0.18);

          if (strongSewageVisual) {
            return DetectionResult(
              category: Category.sewage,
              specificType: 'Sewage',
              priority: waterPct >= 0.26 || contrastPct >= 0.22
                  ? 'HIGH'
                  : 'NORMAL',
              confidence: (0.68 + waterPct + brownPct).clamp(0.0, 1.0),
              matchedKeywords: sewageSignals.isNotEmpty
                  ? sewageSignals
                  : const ['overflow', 'drain', 'water'],
              detectionTier: DetectionTier.imageProperties,
              rejectionReason: '',
            );
          }
        }
      } catch (_) {}
    }

    if (electricalScore < 0.55 && sewageScore < 0.55) {
      return null;
    }

    final category = electricalScore >= sewageScore
        ? Category.electrical
        : Category.sewage;
    final score = category == Category.electrical
        ? electricalScore
        : sewageScore;
    final matched = category == Category.electrical
        ? electricalSignals
        : sewageSignals;

    return DetectionResult(
      category: category,
      specificType: category == Category.electrical ? 'Electricity' : 'Sewage',
      priority: _priorityFromSignals(category, matched, score),
      confidence: score.clamp(0.0, 1.0),
      matchedKeywords: matched.isEmpty
          ? [category == Category.electrical ? 'electricity' : 'sewage']
          : matched,
      detectionTier: DetectionTier.imageProperties,
      rejectionReason: '',
    );
  }

  static String _priorityFromSignals(
    Category category,
    List<String> matched,
    double score,
  ) {
    final joined = matched.join(' ').toLowerCase();

    if (category == Category.electrical &&
        (joined.contains('fire') ||
            joined.contains('smoke') ||
            joined.contains('spark') ||
            score >= 0.9)) {
      return 'HIGH';
    }

    if (category == Category.sewage &&
        (joined.contains('overflow') ||
            joined.contains('leak') ||
            joined.contains('flood') ||
            score >= 0.85)) {
      return 'HIGH';
    }

    return score >= 0.75 ? 'NORMAL' : 'LOW';
  }

  static List<String> _electricalTokens() => const [
    'electric',
    'electricity',
    'power',
    'wire',
    'cable',
    'pole',
    'transformer',
    'lamp',
    'light',
    'utility',
  ];

  static List<String> _sewageTokens() => const [
    'sewage',
    'sewer',
    'drain',
    'drainage',
    'manhole',
    'overflow',
    'flood',
    'water',
    'pipe',
    'waste',
    'leak',
  ];

  static bool _matchesAny(String text, List<String> tokens) {
    return tokens.any((token) => text.contains(token));
  }

  static bool _hasInfrastructureSignals(
    List<ImageLabel> labels,
    List<DetectedObject> objects,
    File? imageFile,
  ) {
    if (_hasElectricalSignals(labels) || _hasSewageSignals(labels)) {
      return true;
    }

    if (objects.isNotEmpty && _hasElectricalVisualSignals(imageFile, objects)) {
      return true;
    }

    if (imageFile != null && _hasSewageVisualSignals(imageFile)) {
      return true;
    }

    return false;
  }

  static bool _hasSewageVisualSignals(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      final thumbnail = img.copyResize(image, width: 120, height: 120);
      final properties = _sampleImageProperties(thumbnail);

      return properties['brownPercentage']! > 0.03 ||
          properties['waterLikePercentage']! > 0.06 ||
          properties['highContrastPixels']! > 0.18;
    } catch (_) {
      return false;
    }
  }

  static bool _hasElectricalVisualSignals(
    File? imageFile,
    List<DetectedObject> objects,
  ) {
    if (imageFile == null || objects.isEmpty) return false;

    try {
      final bytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      final thumbnail = img.copyResize(image, width: 120, height: 120);
      final properties = _sampleImageProperties(thumbnail);
      final hasCompatibleShape = objects.any((object) {
        final shape = ImprovedShapeAnalyzer.analyzeObject(object).primaryShape;
        return shape == ShapeType.tall ||
            shape == ShapeType.boxLike ||
            shape == ShapeType.linear;
      });

      return hasCompatibleShape &&
          (properties['highContrastPixels']! > 0.16 ||
              properties['firePercentage']! > 0.04);
    } catch (_) {
      return false;
    }
  }

  static _ScoreResult _calculateBoostedScore(
    KeywordMatchResult match,
    List<ShapeAnalysisResult> shapes,
    List<ImageLabel> labels,
    Category category,
  ) {
    if (!match.hasMatch) {
      return _ScoreResult(0.0, null, []);
    }

    double confidence = match.confidence;
    final keywords = List<String>.from(match.matchedKeywords);

    // 1. Shape Boost
    for (var shape in shapes) {
      if (ImprovedShapeAnalyzer.isShapeCompatible(
        shape.primaryShape,
        match.detectedType!,
      )) {
        // We boost by config value scaled by shape confidence
        final boost = DetectionConfig.shapeConfidenceBoost * shape.confidence;
        confidence += boost;
        keywords.add('✓shape_confirmed(${shape.primaryShape.name})');
        debugPrint(
          '  Shape boost: +${boost.toStringAsFixed(2)} '
          '(${shape.primaryShape.name} matches ${match.detectedType})',
        );
        break;
      }
    }

    // 2. Context Boost
    final contextBoost = ImprovedKeywordMatcher.calculateContextBoost(labels);
    confidence += contextBoost;

    return _ScoreResult(
      confidence.clamp(0.0, 1.0),
      match.detectedType,
      keywords,
    );
  }

  static Map<String, double> _sampleImageProperties(img.Image image) {
    int firePixels = 0;
    int highContrastPixels = 0;
    int brownPixels = 0;
    int waterLikePixels = 0;
    int totalPixels = 0;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        totalPixels++;

        // Fire
        if ((r > 150 && g > 80 && b < 100 && r > g) ||
            (r > 180 && g > 120 && b < 80) ||
            (r > 200 && g > 180 && b > 100)) {
          firePixels++;
        }

        // Contrast
        final brightness = (r + g + b) / 3;
        if (brightness > 220 || brightness < 40) {
          highContrastPixels++;
        }

        // Brown
        if (r > 120 && g > 80 && g < 150 && b < 100 && r > g) {
          brownPixels++;
        }

        // Water-like reflection/flow surfaces (bluish or gray reflective regions)
        final channelSpread = (r - b).abs();
        if ((b > g && b > r && b > 70) ||
            (brightness > 90 && brightness < 200 && channelSpread < 20)) {
          waterLikePixels++;
        }
      }
    }

    return {
      'firePercentage': firePixels / totalPixels,
      'highContrastPixels': highContrastPixels / totalPixels,
      'brownPercentage': brownPixels / totalPixels,
      'waterLikePercentage': waterLikePixels / totalPixels,
    };
  }

  static DetectionResult _finalizeResult(
    _TierResult tierResult,
    List<ImageLabel> labels,
    File? imageFile,
    DetectionTier tier,
  ) {
    // Priority Assessment
    final rawPriority = ImprovedKeywordMatcher.assessPriority(labels);
    final priority = _normalizePriority(rawPriority, tierResult.category, tier);
    final scopedType = _normalizeTypeForScope(tierResult);

    return DetectionResult(
      category: tierResult.category,
      specificType: scopedType,
      priority: priority,
      confidence: tierResult.confidence,
      matchedKeywords: tierResult.keywords,
      detectionTier: tier,
    );
  }

  static String _normalizeTypeForScope(_TierResult tierResult) {
    final raw = tierResult.type?.trim();
    if (raw == null || raw.isEmpty) {
      return tierResult.category == Category.electrical
          ? 'Electricity'
          : 'Sewage';
    }

    final lower = raw.toLowerCase();
    if (tierResult.category == Category.electrical) {
      if (lower.contains('electric') ||
          lower.contains('wire') ||
          lower.contains('pole') ||
          lower.contains('transformer') ||
          lower.contains('light')) {
        return raw;
      }
      return 'Electricity';
    }

    if (lower.contains('sew') ||
        lower.contains('drain') ||
        lower.contains('manhole') ||
        lower.contains('overflow') ||
        lower.contains('pipe')) {
      return raw;
    }
    return 'Sewage';
  }

  static String _normalizePriority(
    String rawPriority,
    Category category,
    DetectionTier tier,
  ) {
    if (rawPriority == 'HIGH' || rawPriority == 'NORMAL') {
      return rawPriority;
    }

    // Tier-3 classifications are heuristic; avoid under-prioritizing obvious utility reports.
    if (tier == DetectionTier.imageProperties) {
      return 'NORMAL';
    }

    if (category == Category.sewage) {
      return 'NORMAL';
    }

    return 'LOW';
  }
}

class _TierResult {
  final Category category;
  final String? type;
  final double confidence;
  final List<String> keywords;

  _TierResult({
    required this.category,
    this.type,
    required this.confidence,
    required this.keywords,
  });
}

class _ScoreResult {
  final double confidence;
  final String? type;
  final List<String> keywords;

  _ScoreResult(this.confidence, this.type, this.keywords);
}
