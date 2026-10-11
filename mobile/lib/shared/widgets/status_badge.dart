import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radii.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final String?
      type; // "Done", "Now", "Upcoming", "Attended", "Absent", "Not Held"
  final VoidCallback? onTap;

  const StatusBadge({
    super.key,
    required this.label,
    this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;

    final normalized = (type ?? label).toLowerCase();

    switch (normalized) {
      case 'done':
      case 'attended':
        bgColor = AppColors.sageLight;
        textColor = AppColors.sageDark;
        border =
            Border.all(color: AppColors.sage.withValues(alpha: 0.3), width: 1);
        break;
      case 'now':
        bgColor = const Color(0xFFFBECE9);
        textColor = AppColors.terracotta;
        border = Border.all(
            color: AppColors.terracotta.withValues(alpha: 0.4), width: 1);
        break;
      case 'absent':
      case 'critical':
        bgColor = AppColors.coralLight;
        textColor = AppColors.coral;
        border =
            Border.all(color: AppColors.coral.withValues(alpha: 0.4), width: 1);
        break;
      case 'not held':
      case 'holiday':
        bgColor = const Color(0xFFF2F0EE);
        textColor = AppColors.inkMuted;
        border = Border.all(color: AppColors.divider, width: 1);
        break;
      case 'upcoming':
      default:
        bgColor = const Color(0xFFF5F2EF);
        textColor = AppColors.inkMuted;
        border = Border.all(color: AppColors.divider, width: 1);
        break;
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.radiusPill,
        border: border,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
