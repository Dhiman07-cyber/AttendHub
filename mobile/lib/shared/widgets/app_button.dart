import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool showArrow;
  final bool isLoading;
  final bool isSecondary;
  final bool isGlass;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.showArrow = true,
    this.isLoading = false,
    this.isSecondary = false,
    this.isGlass = false,
    this.width,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isLoading && widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonContent;

    if (widget.isGlass) {
      buttonContent = Container(
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(255, 255, 255, 0.90),
              Color.fromRGBO(255, 255, 255, 0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadii.radiusXl,
          border: Border.all(
            color: Colors.white,
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(58, 35, 25, 0.06),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.radiusXl,
            splashColor: AppColors.terracotta.withValues(alpha: 0.15),
            highlightColor: AppColors.terracotta.withValues(alpha: 0.08),
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: _buildInner(textColor: AppColors.terracotta),
            ),
          ),
        ),
      );
    } else if (widget.isSecondary) {
      buttonContent = SizedBox(
        width: widget.width ?? double.infinity,
        child: Listener(
          onPointerDown: (_) {
            if (!widget.isLoading && widget.onPressed != null) {
              setState(() => _isPressed = true);
            }
          },
          onPointerUp: (_) {
            if (_isPressed) setState(() => _isPressed = false);
          },
          onPointerCancel: (_) {
            if (_isPressed) setState(() => _isPressed = false);
          },
          child: OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              side: const BorderSide(color: AppColors.terracotta, width: 1.2),
              shape:
                  const RoundedRectangleBorder(borderRadius: AppRadii.radiusXl),
              backgroundColor: Colors.white,
            ),
            child: _buildInner(textColor: AppColors.terracotta),
          ),
        ),
      );
    } else {
      buttonContent = Container(
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE26B55), // Terracotta gradient
              Color(0xFFCE5944),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppRadii.radiusXl,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1.0,
          ),
          boxShadow: AppShadows.button,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.radiusXl,
            splashColor: Colors.white.withValues(alpha: 0.22),
            highlightColor: Colors.white.withValues(alpha: 0.10),
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Padding(
              padding: widget.padding ??
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: _buildInner(textColor: Colors.white),
            ),
          ),
        ),
      );
    }

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: buttonContent,
    );
  }

  Widget _buildInner({required Color textColor}) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: textColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: AppTypography.button.copyWith(color: textColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (widget.showArrow) ...[
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 18, color: textColor),
        ],
      ],
    );
  }
}
