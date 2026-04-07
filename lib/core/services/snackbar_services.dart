import 'package:flutter/material.dart';
import 'package:batti_nala/core/constants/colors.dart';

class SnackbarService {
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String englishMessage,
    required String nepaliMessage,
    String buttonText = 'OK',
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.adminRedLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.adminRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                englishMessage,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                nepaliMessage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue900,
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  static void showError(
    BuildContext context,
    String message, [
    String? actionLabel,
    VoidCallback? onAction,
  ]) {
    _showTopSnackBar(
      context,
      message,
      Colors.red,
      Icons.error,
      actionLabel,
      onAction,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      Colors.green,
      Icons.check_circle,
      null,
      null,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      Colors.blueGrey,
      Icons.info_outline,
      null,
      null,
    );
  }

  static void _showTopSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  ) {
    if (!context.mounted) return;
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: color,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  GestureDetector(
                    onTap: () {
                      onAction();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }
}
