import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AttendanceProgressRing extends StatelessWidget {
  final double? percentage;
  final int attended;
  final int conducted;
  final double targetPercentage;
  final double minimumPercentage;
  final double trendChange;
  final double size;

  const AttendanceProgressRing({
    super.key,
    required this.percentage,
    required this.attended,
    required this.conducted,
    this.targetPercentage = 75.0,
    this.minimumPercentage = 75.0,
    this.trendChange = 0.0,
    this.size = 130.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final pct = percentage ?? 0.0;
    final progress = (pct / 100.0).clamp(0.0, 1.0);

    // Color based on standing
    Color progressColor = AppColors.sage;
    if (pct < minimumPercentage) {
      progressColor = AppColors.coral;
    } else if (pct < targetPercentage) {
      progressColor = AppColors.amber;
    }

    final isCompact = screenWidth < 400 || size <= 110;
    final ringSize = screenWidth < 350
        ? 62.0
        : (screenWidth < 370
            ? 68.0
            : (screenWidth < 390
                ? 72.0
                : (isCompact ? min(size, 80.0) : size)));
    final gap = screenWidth < 370 ? 5.0 : (isCompact ? 7.0 : 12.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
            // Circular Progress Ring
            SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(ringSize, ringSize),
                      painter: _RingPainter(
                        progress: progress,
                        progressColor: progressColor,
                        trackColor: progressColor.withValues(alpha: 0.14),
                        strokeWidth: isCompact ? 6.5 : 9.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isCompact ? 6.0 : 10.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            percentage != null
                                ? '${percentage!.toStringAsFixed(1)}%'
                                : '0.0%',
                            style: AppTypography.displayPercentage.copyWith(
                              fontSize: isCompact ? 15 : 22,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            conducted > 0 ? '$attended / $conducted' : '0 / 0',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isCompact ? 9.5 : 12,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                          if (!isCompact)
                            Text(
                              'classes',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: gap),

            // Right side info (Target, Minimum, Trend)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Target item
                  _buildTargetItem(
                    icon: Icons.flag_rounded,
                    iconColor: const Color(0xFFE89E4F),
                    bgColor: const Color(0xFFFDF4E8),
                    label: 'Target',
                    value: '${targetPercentage.toStringAsFixed(0)}%',
                    isCompact: isCompact,
                  ),
                  SizedBox(height: isCompact ? 4 : 8),

                  // Minimum item
                  _buildTargetItem(
                    icon: Icons.shield_rounded,
                    iconColor: AppColors.sage,
                    bgColor: AppColors.sageLight,
                    label: 'Minimum',
                    value: '${minimumPercentage.toStringAsFixed(0)}%',
                    isCompact: isCompact,
                  ),
                  SizedBox(height: isCompact ? 4 : 8),

                  // Trend from last month (guaranteed scale down without overflow)
                  // Trend from last month
                  if (conducted > 0 && trendChange != 0.0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trendChange >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: isCompact ? 11 : 14,
                            color:
                                trendChange >= 0 ? AppColors.sage : AppColors.coral,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${trendChange >= 0 ? '+' : ''}${trendChange.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: isCompact ? 10.0 : 12,
                              fontWeight: FontWeight.w700,
                              color: trendChange >= 0
                                  ? AppColors.sageDark
                                  : AppColors.coral,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isCompact ? 'last mo' : 'from last mo',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: isCompact ? 9.0 : 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_rounded,
                            size: isCompact ? 11 : 14,
                            color: AppColors.inkMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'No trend yet',
                            style: TextStyle(
                              fontSize: isCompact ? 9.5 : 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
  }

  Widget _buildTargetItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    bool isCompact = false,
  }) {
    final iconBoxSize = isCompact ? 20.0 : 26.0;
    final iconSize = isCompact ? 12.0 : 15.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(isCompact ? 5 : 7),
            ),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
          SizedBox(width: isCompact ? 5 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: isCompact ? 8.5 : 10.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 11.0 : 13.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final arcPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor;
}
