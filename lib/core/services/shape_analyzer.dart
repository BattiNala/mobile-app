import 'package:batti_nala/core/services/detection.dart';
import 'package:flutter/widgets.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

enum ShapeType {
  tall, // Poles, posts
  boxLike, // Transformers, junction boxes
  linear, // Wires, cables
  circular, // Manholes
  irregular, // Complex shapes
  unknown,
}

class ShapeAnalysisResult {
  final ShapeType primaryShape;
  final double confidence;
  final Map<String, double> shapeScores; // All shape scores
  final String description;

  ShapeAnalysisResult({
    required this.primaryShape,
    required this.confidence,
    required this.shapeScores,
    required this.description,
  });
}

class ImprovedShapeAnalyzer {
  /// Analyze object shape with confidence scoring
  static ShapeAnalysisResult analyzeObject(DetectedObject object) {
    final rect = object.boundingBox;
    final width = rect.width;
    final height = rect.height;
    final aspectRatio = height / width;
    final area = width * height;

    debugPrint(
      'Shape Analysis: ${width.toStringAsFixed(0)}x${height.toStringAsFixed(0)}, '
      'AR=${aspectRatio.toStringAsFixed(2)}, area=${area.toStringAsFixed(0)}',
    );

    final scores = <String, double>{};

    // TALL SHAPE SCORE (Poles, Posts)
    scores['tall'] = _calculateTallScore(aspectRatio, area);

    // BOX-LIKE SCORE (Transformers, Utility Boxes)
    scores['boxLike'] = _calculateBoxScore(aspectRatio, area);

    // LINEAR SCORE (Wires, Cables)
    scores['linear'] = _calculateLinearScore(aspectRatio, width, height);

    // CIRCULAR SCORE (Manholes)
    scores['circular'] = _calculateCircularScore(aspectRatio, area);

    // IRREGULAR SCORE (Complex objects)
    scores['irregular'] = _calculateIrregularScore(aspectRatio, area);

    // Find highest scoring shape
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topShape = sortedScores.first;
    final shapeType = _scoreToShapeType(topShape.key);
    final confidence = topShape.value;

    final description = _getShapeDescription(shapeType, confidence);

    debugPrint('  Shape Scores: ${_formatScores(scores)}');
    debugPrint(
      '  Result: $shapeType (confidence: ${confidence.toStringAsFixed(2)})',
    );

    return ShapeAnalysisResult(
      primaryShape: shapeType,
      confidence: confidence,
      shapeScores: scores,
      description: description,
    );
  }

  static double _calculateTallScore(double aspectRatio, double area) {
    double score = 0.0;

    // Perfect pole: AR > 3, large area
    if (aspectRatio > 3.0 && area > 8000) {
      score = 0.95;
    } else if (aspectRatio > DetectionConfig.tallAspectRatio &&
        area > DetectionConfig.tallMinArea) {
      // Good pole match
      score = 0.80;
    } else if (aspectRatio > 2.0 && area > 3000) {
      // Possible pole
      score = 0.60;
    } else if (aspectRatio > 1.8) {
      // Weak pole signal
      score = 0.35;
    }

    return score;
  }

  static double _calculateBoxScore(double aspectRatio, double area) {
    double score = 0.0;

    // Perfect box: AR close to 1.0, decent area
    final deviation = (aspectRatio - 1.0).abs();

    if (deviation < 0.2 && area > 5000) {
      score = 0.90;
    } else if (aspectRatio >= DetectionConfig.boxAspectRatioMin &&
        aspectRatio <= DetectionConfig.boxAspectRatioMax &&
        area > DetectionConfig.boxMinArea) {
      // Good box match
      score = 0.75;
    } else if (aspectRatio >= 0.5 && aspectRatio <= 1.6 && area > 2000) {
      // Possible box
      score = 0.55;
    } else if (aspectRatio >= 0.4 && aspectRatio <= 1.8) {
      // Weak box signal
      score = 0.30;
    }

    return score;
  }

  static double _calculateLinearScore(
    double aspectRatio,
    double width,
    double height,
  ) {
    double score = 0.0;

    // Linear: very wide or very tall
    if (aspectRatio < 0.25 && width > height * 5) {
      score = 0.90; // Strong horizontal line
    } else if (aspectRatio < DetectionConfig.linearAspectRatio &&
        width > height * DetectionConfig.linearWidthMultiplier) {
      score = 0.75;
    } else if (aspectRatio < 0.4 && width > height * 3) {
      score = 0.60;
    } else if (aspectRatio < 0.5) {
      score = 0.35;
    }

    return score;
  }

  static double _calculateCircularScore(double aspectRatio, double area) {
    double score = 0.0;

    // Circular: AR close to 1.0
    final deviation = (aspectRatio - 1.0).abs();

    if (deviation < 0.1 && area > 3000) {
      score = 0.85; // Very circular
    } else if (aspectRatio >= DetectionConfig.circularAspectRatioMin &&
        aspectRatio <= DetectionConfig.circularAspectRatioMax &&
        area > DetectionConfig.circularMinArea) {
      score = 0.70;
    } else if (deviation < 0.3 && area > 1500) {
      score = 0.50;
    } else if (deviation < 0.4) {
      score = 0.30;
    }

    return score;
  }

  static double _calculateIrregularScore(double aspectRatio, double area) {
    // Irregular gets higher score when other shapes don't fit well
    if (area < 1000) return 0.20; // Too small

    // If AR is in weird ranges, likely irregular
    if ((aspectRatio > 1.5 && aspectRatio < 2.0) ||
        (aspectRatio > 0.5 && aspectRatio < 0.6)) {
      return 0.50;
    }

    return 0.25; // Default low score
  }

  static ShapeType _scoreToShapeType(String scoreKey) {
    switch (scoreKey) {
      case 'tall':
        return ShapeType.tall;
      case 'boxLike':
        return ShapeType.boxLike;
      case 'linear':
        return ShapeType.linear;
      case 'circular':
        return ShapeType.circular;
      case 'irregular':
        return ShapeType.irregular;
      default:
        return ShapeType.unknown;
    }
  }

  static String _getShapeDescription(ShapeType type, double confidence) {
    switch (type) {
      case ShapeType.tall:
        return confidence > 0.7 ? 'Pole-like structure' : 'Possible pole';
      case ShapeType.boxLike:
        return confidence > 0.7 ? 'Box-like structure' : 'Possible box';
      case ShapeType.linear:
        return confidence > 0.7 ? 'Linear structure' : 'Possible wire/cable';
      case ShapeType.circular:
        return confidence > 0.7 ? 'Circular structure' : 'Possible manhole';
      case ShapeType.irregular:
        return 'Irregular shape';
      default:
        return 'Unknown shape';
    }
  }

  static String _formatScores(Map<String, double> scores) {
    return scores.entries
        .map((e) => '${e.key}=${e.value.toStringAsFixed(2)}')
        .join(', ');
  }

  /// Check if shape matches expected type for category
  static bool isShapeCompatible(
    ShapeType detectedShape,
    String infrastructureType,
  ) {
    switch (infrastructureType) {
      case 'Electric Pole':
      case 'Street Light':
        return detectedShape == ShapeType.tall;

      case 'Transformer':
        return detectedShape == ShapeType.boxLike;

      case 'Wire':
        return detectedShape == ShapeType.linear;

      case 'Manhole':
        return detectedShape == ShapeType.circular;

      default:
        return true; // Unknown types compatible with any shape
    }
  }
}
