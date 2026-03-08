import 'package:flutter/material.dart';

class SnackbarService {
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

  static void _showTopSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  ) {
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
