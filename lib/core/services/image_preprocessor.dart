import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagePreprocessor {
  /// Enhances an image file for better ML Kit recognition.
  /// Returns the path to the enhanced temporary file.
  static Future<String> preprocess(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return filePath;

      print(
        'AI Debug: Pre-processing image (original: ${image.width}x${image.height})',
      );

      // 1. Downscale for faster ML processing (max 1200px)
      // ML Kit doesn't need high res, and downscaling reduces sensor noise
      if (image.width > 1200 || image.height > 1200) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1200 : null,
          height: image.height >= image.width ? 1200 : null,
          interpolation: img.Interpolation.linear,
        );
        print('AI Debug: Downscaled to ${image.width}x${image.height}');
      }

      // 2. Adaptive Contrast / Brightness
      // Infrastructure like wires often gets lost in bright sky or dark shadows
      // We apply moderate contrast to make edges pop
      final enhanced = img.adjustColor(
        image,
        contrast: 1.25,
        brightness: 1.05,
        exposure: 1.1,
      );

      // 3. Optimized Sharpening for edge detection of wires/poles
      // This helps ML Kit distinguish thin elements against the background
      final sharpened = img.convolution(
        enhanced,
        filter: [-0.5, -1.0, -0.5, -1.0, 7.0, -1.0, -0.5, -1.0, -0.5],
      );

      // Save to a temporary location
      final tempDir = await getTemporaryDirectory();
      final fileName = 'enhanced_${p.basename(filePath)}';
      final enhancedPath = p.join(tempDir.path, fileName);

      final encoded = img.encodeJpg(sharpened, quality: 85);
      await File(enhancedPath).writeAsBytes(encoded);

      print('AI Debug: Enhanced image saved at $enhancedPath');
      return enhancedPath;
    } catch (e) {
      print('AI Debug: Pre-processing failed, using original: $e');
      return filePath;
    }
  }
}
