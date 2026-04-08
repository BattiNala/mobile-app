import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:batti_nala/core/services/image_preprocessor.dart';

class AIAnalysisResult {
  final List<ImageLabel> labels;
  final List<DetectedObject> objects;
  final String enhancedImagePath;

  AIAnalysisResult({
    required this.labels,
    required this.objects,
    required this.enhancedImagePath,
  });
}

class MLKitService {
  late ImageLabeler _labeler;
  late ObjectDetector _objectDetector;

  MLKitService() {
    _labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.4),
    );

    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  Future<AIAnalysisResult> processImage(String filePath) async {
    debugPrint('AI Debug: Starting Multi-Model Analysis...');

    // 1. Pre-process image for better clarity
    final enhancedPath = await ImagePreprocessor.preprocess(filePath);
    final inputImage = InputImage.fromFile(File(enhancedPath));

    // 2. Run models in parallel (with fallback if native detector is unlinked)
    List<ImageLabel> labels = [];
    List<DetectedObject> objects = [];

    try {
      final results = await Future.wait([
        _labeler.processImage(inputImage),
        _objectDetector.processImage(inputImage),
      ]);
      labels = results[0] as List<ImageLabel>;
      objects = results[1] as List<DetectedObject>;
    } catch (e) {
      if (e.toString().contains('MissingPluginException')) {
        debugPrint(
          'AI Debug: ObjectDetector not yet linked (Restart required). Falling back to Labeler only.',
        );
        labels = await _labeler.processImage(inputImage);
      } else {
        rethrow;
      }
    }

    debugPrint(
      'AI Debug: Completed with ${labels.length} labels and ${objects.length} objects',
    );

    for (var label in labels) {
      debugPrint(
        'AI Debug: Label: ${label.label}, Confidence: ${label.confidence}',
      );
    }

    for (var object in objects) {
      final rect = object.boundingBox;
      debugPrint(
        'AI Debug: Object found at [${rect.left.toInt()}, ${rect.top.toInt()}] '
        'Size: ${rect.width.toInt()}x${rect.height.toInt()}',
      );
    }

    return AIAnalysisResult(
      labels: labels,
      objects: objects,
      enhancedImagePath: enhancedPath,
    );
  }

  void dispose() {
    _labeler.close();
    _objectDetector.close();
  }
}
