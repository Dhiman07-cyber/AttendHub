import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/subject_model.dart';
import '../../shared/widgets/liquid_glass_card.dart';
import '../../shared/widgets/status_badge.dart';
import 'providers/subjects_provider.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final SubjectModel subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = subject.conducted > 0;
    final pct = subject.percentage;
    final isCritical = hasData && pct != null && pct < 75.0;


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subjects'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Card
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.code ?? 'Subject Detail',
                              style: AppTypography.bodySmall
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subject.name,
                              style: AppTypography.titleLarge,
                              softWrap: true,
                            ),
                            if (subject.facultyName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subject.facultyName!,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: hasData ? subject.statusLabel : 'No data yet',
                        type: hasData ? subject.status : 'NO_DATA',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 14),

                  // Metrics Row - each column wrapped in Expanded
                  Row(
                    children: [
                      _buildMetricCol(
                        label: 'Attendance',
                        value: hasData && pct != null
                            ? '${pct.toStringAsFixed(1)}%'
                            : '0.0%',
                        color: !hasData
                            ? AppColors.inkMuted
                            : (isCritical ? AppColors.coral : AppColors.sageDark),
                      ),
                      _buildMetricCol(
                        label: 'Attended',
                        value: '${subject.attended}',
                        color: AppColors.ink,
                      ),
                      _buildMetricCol(
                        label: 'Conducted',
                        value: '${subject.conducted}',
                        color: AppColors.ink,
                      ),
                    ],
                  ),

                  // Visual Progress Bar vs 75% Target
                  if (hasData && pct != null) ...[
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress to Target',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Target: 75.0%',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFE8E2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (pct / 100.0).clamp(0.0, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isCritical
                                      ? AppColors.coral
                                      : AppColors.sageDark,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  if (!hasData) ...[
                    const SizedBox(height: 12),
                    Text(
                      'No attendance data yet',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.inkMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Intelligence / Forecast Card
            const Text(
              'Attendance Forecast',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 10),

            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Safe Absence info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.sageLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_outlined,
                            color: AppColors.sage, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Safe Absence Margin',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasData
                                  ? (subject.canMissMessage ??
                                      'You can miss up to ${subject.maxSafeAbsences} classes and stay above 75%.')
                                  : 'No attendance data yet. Attend classes regularly once sessions begin.',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 14),

                  // Target Recovery info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBECE9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.track_changes_outlined,
                            color: AppColors.terracotta, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target Reach',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasData
                                  ? (subject.recoveryMessage ??
                                      'On track! Keep attending regularly.')
                                  : 'Awaiting attendance records.',
                              style: AppTypography.bodyMedium
                                  .copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Schedule Info
            const Text(
              'Weekly Schedule',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 10),

            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: AppColors.inkMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subject.scheduleSummary ??
                          'No routine schedule configured yet.',
                      style: AppTypography.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Delete Subject Action Card
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.coral),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Delete Subject',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Remove this subject from your semester timetable and active subjects list. Historical attendance totals will remain preserved.',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkMuted,
                        height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coral,
                        side: const BorderSide(color: AppColors.coral),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.coral, size: 16),
                      label: const Text(
                        'Delete Subject',
                        style: TextStyle(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('Delete Subject'),
                            content: Text(
                              'Are you sure you want to delete "${subject.name}"?\n\n'
                              'This will remove the subject from your timetable and active subjects.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(dialogCtx);
                                  final success = await ref
                                      .read(subjectsProvider.notifier)
                                      .deleteSubject(subject.id);
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Deleted "${subject.name}".'),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to delete subject.'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: AppColors.coral,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}
