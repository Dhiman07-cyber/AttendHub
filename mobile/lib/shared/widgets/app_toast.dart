import 'dart:async';
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

  static void error(BuildContext context, String message) => showError(context, message);

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

  static void success(BuildContext context, String message) => showSuccess(context, message);

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

  static OverlayEntry? _activeTopToast;

  /// Displays a modern, floating top-right notification toast.
  /// Renders at the top-right corner above dialogs and bottom sheets.
  static void showTopRight(
    BuildContext context,
    String message, {
    IconData icon = Icons.warning_amber_rounded,
    Color backgroundColor = const Color(0xFF2C2522),
    Color accentColor = const Color(0xFFD86A62), // AppColors.coral
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    // Trigger floating SnackBar as accessible fallback
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
    }

    try {
      final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);
      _activeTopToast?.remove();
      _activeTopToast = null;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => _TopRightToastOverlay(
          message: message,
          icon: icon,
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          duration: duration,
          onDismiss: () {
            if (_activeTopToast == entry) {
              entry.remove();
              _activeTopToast = null;
            }
          },
        ),
      );

      _activeTopToast = entry;
      overlay.insert(entry);
    } catch (_) {
      _show(
        context,
        message: message,
        icon: icon,
        backgroundColor: accentColor,
        iconColor: Colors.white,
        duration: duration,
      );
    }
  }

  /// Specialized conflict toast shown prominently at the top right.
  static void showConflict(BuildContext context, String message) {
    showTopRight(
      context,
      message,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFF2C2522),
      accentColor: const Color(0xFFD86A62), // Coral conflict accent
      duration: const Duration(seconds: 4),
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

class _TopRightToastOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopRightToastOverlay({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopRightToastOverlay> createState() => _TopRightToastOverlayState();
}

class _TopRightToastOverlayState extends State<_TopRightToastOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.15, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
    _dismissTimer = Timer(widget.duration, () => _dismiss());
  }

  void _dismiss() {
    if (!mounted) return;
    _animCtrl.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top + 16;
    final maxWidth = (media.size.width - 32).clamp(240.0, 390.0);

    return Positioned(
      top: topPadding,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 18,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: widget.accentColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _dismiss,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
