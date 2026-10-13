import 'package:flutter/material.dart';

/// Centralized, high-fidelity Toast & SnackBar utility for AttendHub.
/// Renders floating, rounded, themed notifications with icons and clear typography.
class AppToast {
  AppToast._();

  /// Displays an error toast with coral accent and error icon.
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFFD86A62), // AppColors.coral
      iconColor: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Displays a success toast with sage accent and checkmark icon.
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: const Color(0xFF437A5C), // Sage dark
      iconColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  /// Displays a "Coming Soon" toast with dark espresso card, amber accent, and hourglass icon.
  static void showComingSoon(BuildContext context, {String feature = 'Upload'}) {
    final text = feature.toLowerCase().contains('coming soon')
        ? feature
        : '$feature is coming soon!';
    _show(
      context,
      message: text,
      icon: Icons.hourglass_top_rounded,
      backgroundColor: const Color(0xFF2C2522), // Warm dark espresso
      iconColor: const Color(0xFFE5A96A), // Amber accent
      duration: const Duration(seconds: 2),
    );
  }

  /// Displays an informational toast with dark warm background.
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: const Color(0xFF2C2522),
      iconColor: const Color(0xFF72A68A),
      duration: const Duration(seconds: 3),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Duration duration,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.1,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
