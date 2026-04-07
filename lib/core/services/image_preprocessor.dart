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

      final avgBrightness = _calculateAverageBrightness(image);
      final isDarkScene = avgBrightness < 110;
      final isBrightScene = avgBrightness > 170;

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

      // 2. Adaptive contrast/brightness for scene type
      // - dark scenes: lift shadows and add a bit more contrast
      // - bright scenes: slightly reduce exposure to preserve edges
      // - normal scenes: apply mild enhancement
      final adjusted = img.adjustColor(
        image,
        contrast: isDarkScene ? 1.35 : (isBrightScene ? 1.12 : 1.22),
        brightness: isDarkScene ? 1.12 : (isBrightScene ? 0.98 : 1.04),
        exposure: isDarkScene ? 1.18 : (isBrightScene ? 0.96 : 1.05),
        saturation: 1.05,
      );

      // 3. Gentle denoise + unsharp mask to keep drainage water and pole edges visible
      final blurred = img.gaussianBlur(adjusted, radius: 1);
      final sharpened = img.convolution(
        blurred,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
      );

      // Save to a temporary location
      final tempDir = await getTemporaryDirectory();
      final fileName = 'enhanced_${p.basename(filePath)}';
      final enhancedPath = p.join(tempDir.path, fileName);

      final encoded = img.encodeJpg(sharpened, quality: 90);
      await File(enhancedPath).writeAsBytes(encoded);

      print('AI Debug: Enhanced image saved at $enhancedPath');
      return enhancedPath;
    } catch (e) {
      print('AI Debug: Pre-processing failed, using original: $e');
      return filePath;
    }
  }

  static double _calculateAverageBrightness(img.Image image) {
    var total = 0.0;
    var samples = 0;
    final stepX = (image.width / 40).ceil().clamp(1, image.width);
    final stepY = (image.height / 40).ceil().clamp(1, image.height);

    for (var y = 0; y < image.height; y += stepY) {
      for (var x = 0; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        total += (pixel.r + pixel.g + pixel.b) / 3;
        samples++;
      }
    }

    return samples == 0 ? 0.0 : total / samples;
  }
}
