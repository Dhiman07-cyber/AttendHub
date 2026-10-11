import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SemesterProgressDial extends StatelessWidget {
  final int currentWeek;
  final int totalWeeks;
  final int weeksRemaining;
  final double progressPercentage;

  const SemesterProgressDial({
    super.key,
    required this.currentWeek,
    required this.totalWeeks,
    required this.weeksRemaining,
    required this.progressPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (progressPercentage / 100.0).clamp(0.0, 1.0);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialSize = screenWidth < 360 ? 74.0 : (screenWidth < 380 ? 78.0 : 86.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
            // Circular dial
            SizedBox(
              width: dialSize,
              height: dialSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size(dialSize, dialSize),
                      painter: _SemesterDialPainter(
                        progress: progress,
                        progressColor: const Color(0xFFF19762),
                        trackColor: const Color(0xFFFBE4D5),
                        strokeWidth: dialSize < 80 ? 6.5 : 8.0,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: dialSize < 80 ? 15 : 18,
                        color: const Color(0xFFD47C42),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$currentWeek / $totalWeeks',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: dialSize < 80 ? 11.5 : 13,
                        ),
                      ),
                      Text(
                        'Weeks',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: dialSize < 80 ? 9 : 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

        const SizedBox(height: 12),

        // Bottom progress indicator & weeks remaining
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: AppColors.terracotta,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$weeksRemaining weeks remaining',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Horizontal bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFFBE4D5),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.terracotta),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _SemesterDialPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _SemesterDialPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

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
  bool shouldRepaint(covariant _SemesterDialPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
