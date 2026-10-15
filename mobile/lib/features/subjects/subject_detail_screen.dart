import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/models/subject_model.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/liquid_glass_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../analytics/providers/analytics_provider.dart';
import '../dashboard/providers/dashboard_provider.dart';
import '../today/providers/today_provider.dart';
import 'providers/subjects_provider.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final SubjectModel subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsState = ref.watch(subjectsProvider);
    final currentSubject = subjectsState.subjects.firstWhere(
      (s) => s.id == subject.id,
      orElse: () => subject,
    );
    final hasData = currentSubject.conducted > 0;
    final pct = currentSubject.percentage;
    final isCritical = hasData && pct != null && pct < 75.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subject Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.ink),
            tooltip: 'Update Attendance',
            onPressed: () => _showAdjustAttendanceSheet(context, ref, currentSubject),
          ),
        ],
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
                              currentSubject.code ?? 'Subject Detail',
                              style: AppTypography.bodySmall
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSubject.name,
                              style: AppTypography.titleLarge,
                              softWrap: true,
                            ),
                            if (currentSubject.facultyName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                currentSubject.facultyName!,
                                style: AppTypography.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: hasData ? currentSubject.statusLabel : 'No data yet',
                        type: hasData ? currentSubject.status : 'NO_DATA',
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
                        value: '${currentSubject.attended}',
                        color: AppColors.ink,
                      ),
                      _buildMetricCol(
                        label: 'Conducted',
                        value: '${currentSubject.conducted}',
                        color: AppColors.ink,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terracotta,
                        side: const BorderSide(color: AppColors.terracotta, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text(
                        'Update Attendance Details',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showAdjustAttendanceSheet(context, ref, currentSubject),
                    ),
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
                  
                  // Theory/Lab Breakdown (NEW)
                  if (hasData && (currentSubject.theoryMetrics?.hasData == true || 
                                 currentSubject.labMetrics?.hasData == true)) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 14),
                    
                    Text(
                      'Theory & Lab Breakdown',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    Row(
                      children: [
                        if (currentSubject.theoryMetrics?.hasData == true)
                          Expanded(
                            child: _buildTypeBreakdownCard(
                              context,
                              label: 'Theory',
                              metrics: currentSubject.theoryMetrics!,
                              color: AppColors.sage,
                            ),
                          ),
                        if (currentSubject.theoryMetrics?.hasData == true && 
                            currentSubject.labMetrics?.hasData == true)
                          const SizedBox(width: 12),
                        if (currentSubject.labMetrics?.hasData == true)
                          Expanded(
                            child: _buildTypeBreakdownCard(
                              context,
                              label: 'Lab',
                              metrics: currentSubject.labMetrics!,
                              color: AppColors.terracotta,
                            ),
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
                                  ? (currentSubject.canMissMessage ??
                                      'You can miss up to ${currentSubject.maxSafeAbsences} classes and stay above 75%.')
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
                                  ? (currentSubject.recoveryMessage ??
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
                  
                  // Semester Forecast (NEW)
                  if (currentSubject.remainingClasses != null) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 24),
                    
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_today_outlined,
                              color: AppColors.terracotta, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Remaining Until Semester End',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentSubject.remainingClasses} total classes remaining',
                                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                              ),
                              if (currentSubject.remainingTheoryClasses != null || 
                                  currentSubject.remainingLabClasses != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${currentSubject.remainingTheoryClasses ?? 0} Theory • ${currentSubject.remainingLabClasses ?? 0} Lab',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (currentSubject.projectedFinalPercentage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.trending_up_outlined,
                                color: AppColors.sage, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Projected Final Attendance',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSubject.projectedFinalPercentage! >= 75.0
                                      ? 'On track to finish at ${currentSubject.projectedFinalPercentage!.toStringAsFixed(1)}% (attending all remaining classes)'
                                      : 'Projected ${currentSubject.projectedFinalPercentage!.toStringAsFixed(1)}% if attending all remaining',
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (currentSubject.maxFutureAbsencesForMin != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: currentSubject.maxFutureAbsencesForMin! > 0
                              ? AppColors.sage.withValues(alpha: 0.05)
                              : AppColors.coral.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentSubject.maxFutureAbsencesForMin! > 0
                                ? AppColors.sage.withValues(alpha: 0.2)
                                : AppColors.coral.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              currentSubject.maxFutureAbsencesForMin! > 0
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_rounded,
                              color: currentSubject.maxFutureAbsencesForMin! > 0
                                  ? AppColors.sage
                                  : AppColors.coral,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentSubject.maxFutureAbsencesForMin! > 0
                                    ? 'You can miss up to ${currentSubject.maxFutureAbsencesForMin} future classes and still reach minimum requirement by semester end'
                                    : 'Must attend all ${currentSubject.remainingClasses ?? 0} remaining classes to meet minimum requirement',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: currentSubject.maxFutureAbsencesForMin! > 0
                                      ? AppColors.ink
                                      : AppColors.coral,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
                      currentSubject.scheduleSummary ??
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
                              'Are you sure you want to delete "${currentSubject.name}"?\n\n'
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
                                      .deleteSubject(currentSubject.id);
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Deleted "${currentSubject.name}".'),
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

  void _showAdjustAttendanceSheet(
    BuildContext context,
    WidgetRef ref,
    SubjectModel currentSubject,
  ) {
    int attended = currentSubject.attended;
    int conducted = currentSubject.conducted;
    final attendedCtrl = TextEditingController(text: '$attended');
    final conductedCtrl = TextEditingController(text: '$conducted');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isInvalid = attended > conducted || attended < 0 || conducted < 0;
          final previewPct = conducted > 0
              ? (attended / conducted * 100.0)
              : null;
          final isBelowTarget = previewPct != null && previewPct < 75.0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Update Attendance Records',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentSubject.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.inkMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Preview Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: conducted == 0
                            ? AppColors.surfaceAlt
                            : (isBelowTarget ? AppColors.coralLight : AppColors.sageLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: conducted == 0
                              ? AppColors.divider
                              : (isBelowTarget
                                  ? AppColors.coral.withValues(alpha: 0.3)
                                  : AppColors.sage.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            conducted == 0
                                ? Icons.info_outline_rounded
                                : (isBelowTarget
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline_rounded),
                            size: 20,
                            color: conducted == 0
                                ? AppColors.inkMuted
                                : (isBelowTarget ? AppColors.coral : AppColors.sageDark),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conducted == 0
                                      ? 'No attendance data yet'
                                      : 'Calculated: ${previewPct!.toStringAsFixed(1)}% (Target: 75.0%)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: conducted == 0
                                        ? AppColors.ink
                                        : (isBelowTarget ? AppColors.coral : AppColors.sageDark),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Conducted = Attended ($attended) + Absent (${conducted >= attended ? conducted - attended : 0})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Conducted Input (Total classes held)
                    _buildStepperField(
                      label: 'Total Classes Conducted (C)',
                      subtitle: 'Total class sessions held so far',
                      controller: conductedCtrl,
                      value: conducted,
                      onChanged: (newVal) {
                        setSheetState(() {
                          conducted = newVal;
                          conductedCtrl.text = '$conducted';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Attended Input
                    _buildStepperField(
                      label: 'Classes Attended (A)',
                      subtitle: 'Sessions you physically attended',
                      controller: attendedCtrl,
                      value: attended,
                      onChanged: (newVal) {
                        setSheetState(() {
                          attended = newVal;
                          attendedCtrl.text = '$attended';
                        });
                      },
                    ),

                    if (attended > conducted) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Attended classes cannot exceed total conducted classes.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.coral,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.divider,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isInvalid
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                try {
                                  final client = ApiClient();
                                  await client.dio.put(
                                    '${ApiEndpoints.subjects}/${currentSubject.id}/attendance',
                                    data: {'attended': attended, 'conducted': conducted},
                                  );
                                  await ref.read(subjectsProvider.notifier).loadSubjects();
                                  ref.invalidate(dashboardProvider);
                                  ref.invalidate(analyticsProvider);
                                  ref.invalidate(todayProvider);
                                  if (context.mounted) {
                                    AppToast.success(context, 'Attendance updated successfully');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.error(context, 'Failed to update attendance');
                                  }
                                }
                              },
                        child: const Text(
                          'Save Attendance Changes',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepperField({
    required String label,
    required String subtitle,
    required TextEditingController controller,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              onTap: value > 0 ? () => onChanged(value - 1) : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: value > 0 ? AppColors.surfaceAlt : const Color(0xFFF5F3F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 20,
                  color: value > 0 ? AppColors.ink : AppColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
                  ),
                ),
                onChanged: (text) {
                  final parsed = int.tryParse(text);
                  if (parsed != null && parsed >= 0) {
                    onChanged(parsed);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => onChanged(value + 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(Icons.add_rounded, size: 20, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildTypeBreakdownCard(
    BuildContext context, {
    required String label,
    required TypeBreakdownMetrics metrics,
    required Color color,
  }) {
    final pct = metrics.percentage;
    final isCritical = pct != null && pct < 75.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct != null ? '${pct.toStringAsFixed(1)}%' : '0.0%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isCritical ? AppColors.coral : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${metrics.attended}/${metrics.conducted} classes',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.inkMuted,
            ),
          ),
          if (metrics.classesNeededForMin != null && metrics.classesNeededForMin! > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Need ${metrics.classesNeededForMin} more',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coral,
                ),
              ),
            ),
          ] else if (metrics.maxSafeAbsences > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Can miss ${metrics.maxSafeAbsences}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sage,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
