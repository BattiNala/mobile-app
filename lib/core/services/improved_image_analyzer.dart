import 'dart:io';
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
    print('═══════════════════════════════════════════════════════════');
    print('🔍 IMPROVED MULTI-TIER ANALYSIS');
    print('═══════════════════════════════════════════════════════════');

    final labels = aiResult.labels;
    final objects = aiResult.objects;

    print('\n📊 ML Kit Results:');
    print('  Labels: ${labels.length}');
    print('  Objects: ${objects.length}');

    // === STEP 1: REJECTION CHECK ===
    print('\n[STEP 1] Checking for non-infrastructure...');
    final rejectionResult = ImprovedKeywordMatcher.checkRejection(labels);
    if (rejectionResult.hasMatch) {
      print('❌ REJECTED: Non-infrastructure detected');
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
    print('  ✓ No high-confidence rejection keywords found');

    // === STEP 2: SHAPE ANALYSIS ===
    print('\n[STEP 2] Analyzing object shapes...');
    final shapeResults = objects
        .map((obj) => ImprovedShapeAnalyzer.analyzeObject(obj))
        .toList();

    // === TIER 1: ML KIT + SHAPE (Primary) ===
    print('\n[TIER 1] ML Kit Label + Shape Detection...');
    final tier1Result = _runTier1(labels, shapeResults);

    if (tier1Result != null &&
        tier1Result.confidence >= DetectionConfig.mlKitMinConfidence) {
      print('✅ TIER 1 SUCCESS');
      return _finalizeResult(
        tier1Result,
        labels,
        imageFile,
        DetectionTier.mlKit,
      );
    }

    print('⚠️  Tier 1 FAILED: Insufficient confidence, trying Tier 2...');

    // === TIER 2: KEYWORD INFERENCE (Secondary) ===
    print('\n[TIER 2] Keyword Inference Fallback (STRICT MODE)...');
    final tier2Result = _runTier2(labels, shapeResults);

    if (tier2Result != null &&
        tier2Result.confidence >= DetectionConfig.inferenceMinConfidence) {
      print('✅ TIER 2 SUCCESS');
      return _finalizeResult(
        tier2Result,
        labels,
        imageFile,
        DetectionTier.inference,
      );
    }

    print('⚠️  Tier 2 FAILED: Trying Tier 3...');

    // === TIER 3: IMAGE PROPERTIES (Tertiary) ===
    if (imageFile != null) {
      print('\n[TIER 3] Image Properties Analysis...');
      final tier3Result = _runTier3(imageFile);

      if (tier3Result != null &&
          tier3Result.confidence >=
              DetectionConfig.imagePropertiesMinConfidence) {
        print('✅ TIER 3 SUCCESS');
        return _finalizeResult(
          tier3Result,
          labels,
          imageFile,
          DetectionTier.imageProperties,
        );
      }
    }

    // === FINAL: ALL TIERS FAILED ===
    print('\n❌ ALL TIERS FAILED: Cannot detect infrastructure');
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

    print(
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

  static _TierResult? _runTier3(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Downsample for performance (Plan says 60% faster)
      final thumbnail = img.copyResize(image, width: 200, height: 200);

      final properties = _sampleImageProperties(thumbnail);
      print('  Properties: $properties');

      String? type;
      Category? category;
      double maxConf = 0.0;
      final keywords = <String>[];

      // Fire Detection
      if (properties['firePercentage']! >
          DetectionConfig.firePercentageThreshold) {
        type = 'Emergency - Fire';
        category = Category.electrical;
        maxConf =
            properties['firePercentage']! >
                DetectionConfig.emergencyFireThreshold
            ? 0.85
            : 0.70;
        keywords.add('🔥fire_colors_detected');
      }

      // Metal/Transformer (High Contrast)
      if (category == null &&
          properties['highContrastPixels']! >
              DetectionConfig.highContrastThreshold) {
        type = 'Metal/Transformer';
        category = Category.electrical;
        maxConf = 0.60;
        keywords.add('high_contrast_metal');
      }

      // Sewage/Brown
      if (category == null &&
          properties['brownPercentage']! >
              DetectionConfig.brownPercentageThreshold) {
        type = 'Sewage/Corrosion';
        category = Category.sewage;
        maxConf = 0.58;
        keywords.add('brown_sewage_corrosion');
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
      print('  ❌ Tier 3 Error: $e');
    }
    return null;
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
        print(
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
      }
    }

    return {
      'firePercentage': firePixels / totalPixels,
      'highContrastPixels': highContrastPixels / totalPixels,
      'brownPercentage': brownPixels / totalPixels,
    };
  }

  static DetectionResult _finalizeResult(
    _TierResult tierResult,
    List<ImageLabel> labels,
    File? imageFile,
    DetectionTier tier,
  ) {
    // Priority Assessment
    final priority = ImprovedKeywordMatcher.assessPriority(labels);

    return DetectionResult(
      category: tierResult.category,
      specificType: tierResult.type,
      priority: priority,
      confidence: tierResult.confidence,
      matchedKeywords: tierResult.keywords,
      detectionTier: tier,
    );
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
