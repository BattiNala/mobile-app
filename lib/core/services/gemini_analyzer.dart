import 'dart:convert';
import 'dart:io';
import 'package:batti_nala/core/constants/prompt.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAnalyzerResult {
  final String issueType;
  final String priority;
  final double confidence;
  final String description;

  const GeminiAnalyzerResult({
    required this.issueType,
    required this.priority,
    required this.confidence,
    required this.description,
  });

  factory GeminiAnalyzerResult.fromJson(Map<String, dynamic> json) {
    return GeminiAnalyzerResult(
      issueType: json['issueType']?.toString() ?? 'none',
      priority: json['priority']?.toString() ?? 'NORMAL',
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : double.tryParse(json['confidence'].toString()) ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }

  // Fallback result for errors
  factory GeminiAnalyzerResult.error() {
    return const GeminiAnalyzerResult(
      issueType: 'none',
      priority: 'LOW',
      confidence: 0.0,
      description: 'Could not analyze image',
    );
  }
}

class GeminiAnalyzer {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static Future<GeminiAnalyzerResult> analyzeImage(File imageFile) async {
    // Check API key
    if (_apiKey.isEmpty) {
      debugPrint(
        'Gemini Error: GEMINI_API_KEY environment variable is not set.',
      );
      return GeminiAnalyzerResult.error();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          responseMimeType: 'application/json',
        ),
      );

      final imageBytes = await imageFile.readAsBytes();

      // Get proper mime type
      String mimeType = 'image/jpeg';
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'webp') mimeType = 'image/webp';
      if (extension == 'heic') mimeType = 'image/heic';

      debugPrint('--- Gemini Analysis Started ---');
      debugPrint('Model: gemini-2.5-flash');
      debugPrint('MimeType: $mimeType');
      debugPrint('Image Path: ${imageFile.path}');

      final response = await model.generateContent([
        Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)]),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        debugPrint('Gemini Error: Received empty response');
        return GeminiAnalyzerResult.error();
      }

      debugPrint('Raw Gemini Response: ${response.text}');

      String jsonString = response.text!.trim();
      if (jsonString.startsWith('```')) {
        jsonString = jsonString
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
      }

      final jsonResult = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = GeminiAnalyzerResult.fromJson(jsonResult);

      debugPrint('Parsed Gemini Result:');
      debugPrint('  - Issue Type: ${result.issueType}');
      debugPrint('  - Priority: ${result.priority}');
      debugPrint('  - Confidence: ${result.confidence}');
      debugPrint('  - Description: ${result.description}');
      return result;
    } catch (e) {
      debugPrint('Gemini Analysis Failed');
      debugPrint('Error: $e');
      return GeminiAnalyzerResult.error();
    }
  }
}
