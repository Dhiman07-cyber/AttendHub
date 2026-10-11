import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/landscape_header.dart';
import '../../shared/widgets/liquid_glass_card.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../setup/academic_setup_screen.dart';
import 'providers/today_provider.dart';

class TodayScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback? onNavigateToProfile;

  const TodayScreen({
    super.key,
    required this.onOpenDrawer,
    this.onNavigateToProfile,
  });

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final ScrollController _timetableScrollCtrl = ScrollController();

  static const List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _timetableScrollCtrl.dispose();
    super.dispose();
  }

  List<String> _getScheduleDays(TodayState state) {
    final sIdx = _allDays.indexOf(state.startDay);
    final eIdx = _allDays.indexOf(state.endDay);
    if (sIdx != -1 && eIdx != -1 && sIdx <= eIdx) {
      return _allDays.sublist(sIdx, eIdx + 1);
    }
    return const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  }

  List<int> _getScheduleHours(TodayState state) {
    if (state.classStartHour >= state.classEndHour) {
      return const [9, 10, 11, 12, 13, 14, 15, 16];
    }
    return List.generate(
      (state.classEndHour - state.classStartHour).clamp(1, 14),
      (i) => state.classStartHour + i,
    );
  }

  String _formatHourDisplay(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayH = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayH $period';
  }

  int? _parseHour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return int.tryParse(parts[0]);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _findEntryStartingAt(List<Map<String, dynamic>> entries, int dayIdx, int hour) {
    for (final e in entries) {
      final d = e['day_of_week'] is int ? e['day_of_week'] as int : 0;
      if (d == dayIdx) {
        final startH = _parseHour(e['start_time'] as String?);
        if (startH == hour) return e;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findEntrySpanning(List<Map<String, dynamic>> entries, int dayIdx, int hour) {
    for (final e in entries) {
      final d = e['day_of_week'] is int ? e['day_of_week'] as int : 0;
      if (d == dayIdx) {
        final startH = _parseHour(e['start_time'] as String?);
        final endH = _parseHour(e['end_time'] as String?);
        if (startH != null && endH != null && hour > startH && hour < endH) {
          return e;
        }
      }
    }
    return null;
  }

  bool _hasEarlierUpcomingToday(List<Map<String, dynamic>> entries, int dayIdx, int currentHour, int targetStartHour) {
    for (final e in entries) {
      final d = e['day_of_week'] is int ? e['day_of_week'] as int : 0;
      if (d == dayIdx) {
        final startH = _parseHour(e['start_time'] as String?);
        if (startH != null && startH > currentHour && startH < targetStartHour) {
          return true;
        }
      }
    }
    return false;
  }

  void _showSlotDetailsSheet(
    BuildContext context,
    Map<String, dynamic> entry,
    String dayName, {
    required bool isLive,
    required bool isNext,
  }) {
    final subName = entry['subject_name'] as String? ?? 'Class';
    final startTime = entry['start_time'] as String? ?? '09:00';
    final endTime = entry['end_time'] as String? ?? '10:00';
    final room = entry['room'] as String? ?? 'Room 101';
    final faculty = entry['faculty_name'] as String? ?? 'Department Faculty';
    final classType = entry['class_type'] as String? ?? 'Theory';
    final colorHex = entry['subject_color'] as String? ?? '#C96E5B';
    final accentColor = AppColors.getSubjectColor(colorHex);
    final isAttended = entry['is_attended'] == true;
    final isAbsent = entry['is_absent'] == true;
    final isNotHeld = entry['is_not_held'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
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

            // Header Row: Subject Name + Close Button
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.school_rounded, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dayName • $startTime – $endTime',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
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

            const SizedBox(height: 20),

            // Class Detail Chips Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoBadge(Icons.category_outlined, classType, AppColors.terracotta, AppColors.terracottaLight),
                _buildInfoBadge(Icons.meeting_room_outlined, room, AppColors.ocean, AppColors.oceanLight),
                _buildInfoBadge(Icons.person_outline_rounded, faculty, AppColors.sageDark, AppColors.sageLight),
                if (isLive)
                  _buildInfoBadge(Icons.radio_button_checked, 'Live Right Now', AppColors.coral, AppColors.coralLight)
                else if (isNext)
                  _buildInfoBadge(Icons.schedule_rounded, 'Next Class Today', AppColors.amberDark, AppColors.amberLight),
                if (isAttended)
                  _buildInfoBadge(Icons.check_circle_rounded, 'Attended', AppColors.sageDark, AppColors.sageLight)
                else if (isAbsent)
                  _buildInfoBadge(Icons.cancel_outlined, 'Absent', AppColors.coral, AppColors.coralLight)
                else if (isNotHeld)
                  _buildInfoBadge(Icons.remove_circle_outline, 'Not Held', AppColors.inkMuted, const Color(0xFFEFECE9)),
              ],
            ),

            const SizedBox(height: 22),

            // Read-Only Guidance Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: AppColors.inkMuted),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Routine is a read-only weekly schedule. Attendance marking is performed exclusively on the Dashboard.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Open Setup Wizard Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.terracotta,
                  side: const BorderSide(color: AppColors.terracotta),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Edit Routine in Setup Wizard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AcademicSetupScreen(
                        onComplete: () => ref.read(todayProvider.notifier).loadToday(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar / Shell Header
            LandscapeHeaderWidget(
              greeting: 'Weekly Routine',
              userName: 'Plan & Track Classes',
              semesterInfo: '${state.semesterLabel} • Classes',
              showActions: false,
              topOffset: 76,
              isLoading: state.isLoading && state.timetableEntries.isEmpty,
            ),

            const SizedBox(height: 16),

            // Routine Screen Content or Shimmer Skeleton
            if (state.isLoading && state.timetableEntries.isEmpty)
              _buildWeeklyRoutineSkeleton(context)
            else
              _buildWeeklyRoutineView(context, state),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyRoutineSkeleton(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Action Row Skeleton (Today indicator & view toggle)
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(
                  width: 140,
                  height: 32,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                SkeletonBox(
                  width: 90,
                  height: 32,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Timetable Grid Card Skeleton
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timetable header bar
                  Row(
                    children: [
                      const SkeletonBox(
                        width: 48,
                        height: 26,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: List.generate(
                            4,
                            (i) => const Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3),
                                child: SkeletonBox(
                                  height: 26,
                                  borderRadius: BorderRadius.all(Radius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5 Day Rows Skeleton
                  ...List.generate(
                    5,
                    (dayIdx) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const SkeletonBox(
                            width: 48,
                            height: 50,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: List.generate(
                                4,
                                (colIdx) => const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 3),
                                    child: SkeletonBox(
                                      height: 50,
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Legend bar placeholder
                  const SkeletonBox.text(width: 220, height: 12),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Guidance Note Card Skeleton
            const LiquidGlassCard(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  SkeletonBox.circle(size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox.text(width: 160, height: 12),
                        SizedBox(height: 6),
                        SkeletonBox.text(width: 240, height: 10),
                      ],
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

  // ==========================================
  // WEEKLY ROUTINE VIEW
  // ==========================================
  Widget _buildWeeklyRoutineView(BuildContext context, TodayState state) {
    final activeDays = _getScheduleDays(state);
    final hours = _getScheduleHours(state);
    final entries = state.timetableEntries;
    final now = DateTime.now();
    final currentDayIdx = now.weekday - 1; // 0=Mon, 6=Sun
    final currentHour = now.hour;

    const double dayColWidth = 64.0;
    const double hourColWidth = 140.0;
    const double slotHeight = 96.0;

    // Check if empty
    if (state.isTimetableEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LiquidGlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_view_week_rounded, color: AppColors.terracotta, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your timetable isn\'t set up yet.',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Add your recurring classes in the Academic Setup Wizard to view your weekly routine grid.',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Set Up Timetable', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AcademicSetupScreen(
                        onComplete: () => ref.read(todayProvider.notifier).loadToday(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week Navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LiquidGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.ink),
                  onPressed: () {
                    ref.read(todayProvider.notifier).setWeekOffset(state.weekOffset - 1);
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          state.weekLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.ink),
                        ),
                      ),
                      if (state.dateRangeDisplay.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            state.dateRangeDisplay,
                            style: const TextStyle(fontSize: 11, color: AppColors.inkMuted, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.ink),
                  onPressed: () {
                    ref.read(todayProvider.notifier).setWeekOffset(state.weekOffset + 1);
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Hero Spotlight Card (Time-Aware Live / Next Class)
        if (state.weekOffset == 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHeroSpotlightCard(context, state, activeDays, currentDayIdx, currentHour),
          ),
          const SizedBox(height: 14),
        ],

        // Section Title & Routine Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Schedule Grid',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Read-only schedule • Scroll horizontally to inspect slots',
                      style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isLoadingWeek ? AppColors.amberLight : AppColors.sageLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.isLoadingWeek ? 'Updating...' : '${entries.length} slots',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: state.isLoadingWeek ? AppColors.amberDark : AppColors.sageDark,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // FULL WEEKLY TIMETABLE GRID WITH PINNED DAY COLUMN (or scoped skeleton during week switch)
        if (state.isLoadingWeek)
          _buildSkeletonWeeklyGrid(activeDays, hours)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowWarm,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PINNED / FIXED LEFT DAY COLUMN
                Container(
                  width: dayColWidth,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      right: BorderSide(color: AppColors.divider, width: 1.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top Left Header Cell (Corner Intersection)
                      Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9F7F5),
                          border: Border(bottom: BorderSide(color: AppColors.divider)),
                        ),
                        child: const Text(
                          'DAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      // Day Rows Header Labels
                      ...List.generate(activeDays.length, (idx) {
                        final dName = activeDays[idx];
                        final dayIdx = _allDays.indexOf(dName);
                        final isToday = (state.weekOffset == 0) && (dayIdx == currentDayIdx);

                        return Container(
                          height: slotHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isToday ? const Color(0xFFFFF2EE) : Colors.transparent,
                            border: const Border(bottom: BorderSide(color: AppColors.divider)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dName.substring(0, 3).toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: isToday ? AppColors.terracotta : AppColors.ink,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.terracotta,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'TODAY',
                                    style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // 2. SCROLLABLE HORIZONTAL TIMELINE GRID
                Expanded(
                  child: SingleChildScrollView(
                    controller: _timetableScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      width: hourColWidth * hours.length,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Headers Row
                          Container(
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDFCFA),
                              border: Border(bottom: BorderSide(color: AppColors.divider)),
                            ),
                            child: Row(
                              children: hours.map((h) {
                                return Container(
                                  width: hourColWidth,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 10),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: AppColors.divider),
                                    ),
                                  ),
                                  child: Text(
                                    _formatHourDisplay(h),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // Day Slots Rows
                          ...List.generate(activeDays.length, (idx) {
                            final dName = activeDays[idx];
                            final dayIdx = _allDays.indexOf(dName);
                            return _buildDaySlotsRow(
                              context: context,
                              entries: entries,
                              dayName: dName,
                              dayIdx: dayIdx,
                              hours: hours,
                              hourColWidth: hourColWidth,
                              slotHeight: slotHeight,
                              currentDayIdx: currentDayIdx,
                              currentHour: currentHour,
                              isCurrentWeek: state.weekOffset == 0,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Color & Badge Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendChip(AppColors.sageDark, 'Attended (Saved)'),
              _buildLegendChip(AppColors.terracotta, 'Now Active'),
              _buildLegendChip(AppColors.amberDark, 'Next Upcoming'),
              _buildLegendChip(AppColors.inkMuted, 'Scheduled / Unticked'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySlotsRow({
    required BuildContext context,
    required List<Map<String, dynamic>> entries,
    required String dayName,
    required int dayIdx,
    required List<int> hours,
    required double hourColWidth,
    required double slotHeight,
    required int currentDayIdx,
    required int currentHour,
    required bool isCurrentWeek,
  }) {
    final List<Widget> cells = [];
    int i = 0;

    while (i < hours.length) {
      final hour = hours[i];
      final startingEntry = _findEntryStartingAt(entries, dayIdx, hour);

      if (startingEntry != null) {
        final startH = _parseHour(startingEntry['start_time'] as String?) ?? hour;
        final endH = _parseHour(startingEntry['end_time'] as String?) ?? (startH + 1);
        final remainingHours = hours.length - i;
        final span = (endH - startH).clamp(1, remainingHours);
        final blockWidth = hourColWidth * span;

        final isToday = isCurrentWeek && (dayIdx == currentDayIdx);
        final isLiveNow = isToday && currentHour >= startH && currentHour < endH;
        final isNextUpcoming = isToday && currentHour < startH && !_hasEarlierUpcomingToday(entries, dayIdx, currentHour, startH);
        final isAttended = startingEntry['is_attended'] == true;

        cells.add(
          Container(
            width: blockWidth,
            height: slotHeight,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFFFFBF8) : AppColors.surface,
              border: const Border(
                right: BorderSide(color: AppColors.divider),
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: _buildScheduledSlotCard(
              context: context,
              entry: startingEntry,
              dayName: dayName,
              isAttended: isAttended,
              isLive: isLiveNow,
              isNext: isNextUpcoming,
              span: span,
            ),
          ),
        );
        i += span;
      } else {
        final spanningEntry = _findEntrySpanning(entries, dayIdx, hour);
        if (spanningEntry != null) {
          final endH = _parseHour(spanningEntry['end_time'] as String?) ?? (hour + 1);
          final remainingHours = hours.length - i;
          final span = (endH - hour).clamp(1, remainingHours);
          final blockWidth = hourColWidth * span;

          final isToday = isCurrentWeek && (dayIdx == currentDayIdx);
          final startH = _parseHour(spanningEntry['start_time'] as String?) ?? hour;
          final isLiveNow = isToday && currentHour >= startH && currentHour < endH;
          final isAttended = spanningEntry['is_attended'] == true;

          cells.add(
            Container(
              width: blockWidth,
              height: slotHeight,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFFFFFBF8) : AppColors.surface,
                border: const Border(
                  right: BorderSide(color: AppColors.divider),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: _buildScheduledSlotCard(
                context: context,
                entry: spanningEntry,
                dayName: dayName,
                isAttended: isAttended,
                isLive: isLiveNow,
                isNext: false,
                span: span,
              ),
            ),
          );
          i += span;
        } else {
          // Empty Slot Cell
          final isToday = isCurrentWeek && (dayIdx == currentDayIdx);
          cells.add(
            Container(
              width: hourColWidth,
              height: slotHeight,
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFFFFFDFB) : AppColors.surface,
                border: const Border(
                  right: BorderSide(color: Color(0xFFF0EBE6)),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5DDD5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
          i++;
        }
      }
    }

    return Row(children: cells);
  }

  Widget _buildScheduledSlotCard({
    required BuildContext context,
    required Map<String, dynamic> entry,
    required String dayName,
    required bool isAttended,
    required bool isLive,
    required bool isNext,
    required int span,
  }) {
    final subName = entry['subject_name'] as String? ?? 'Class';
    final startTime = entry['start_time'] as String? ?? '09:00';
    final endTime = entry['end_time'] as String? ?? '10:00';
    final room = entry['room'] as String? ?? 'Room 101';
    final classType = entry['class_type'] as String? ?? 'Theory';
    final colorHex = entry['subject_color'] as String? ?? '#C96E5B';
    final accentColor = AppColors.getSubjectColor(colorHex);

    Color cardBg;
    Border? border;

    if (isLive) {
      cardBg = const Color(0xFFFBECE9);
      border = Border.all(color: AppColors.terracotta, width: 1.5);
    } else if (isNext) {
      cardBg = const Color(0xFFFEF7ED);
      border = Border.all(color: AppColors.amberDark, width: 1.2);
    } else {
      cardBg = accentColor.withValues(alpha: 0.08);
      border = Border.all(color: accentColor.withValues(alpha: 0.25), width: 1);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSlotDetailsSheet(
          context,
          entry,
          dayName,
          isLive: isLive,
          isNext: isNext,
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Type Tag + Status Indicator (Tick ONLY when genuinely ATTENDED)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      classType,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NOW',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ] else if (isNext) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.amberDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEXT',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ] else if (isAttended) ...[
                    // Strictly actual persisted ATTENDED record shows a green checkmark
                    const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.sageDark),
                  ],
                ],
              ),

              // Middle: Subject Name
              Text(
                subName,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: isLive ? AppColors.terracottaDark : AppColors.ink,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Bottom: Time & Room
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 10, color: AppColors.inkMuted),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      room.isNotEmpty ? '$startTime-$endTime • $room' : '$startTime-$endTime',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSpotlightCard(
    BuildContext context,
    TodayState state,
    List<String> activeDays,
    int currentDayIdx,
    int currentHour,
  ) {
    final entries = state.timetableEntries;
    Map<String, dynamic>? liveClass;
    Map<String, dynamic>? nextClass;

    final todayEntries = entries.where((t) => (t['day_of_week'] is int ? t['day_of_week'] : 0) == currentDayIdx).toList()
      ..sort((a, b) => ((a['start_time'] as String?) ?? '').compareTo((b['start_time'] as String?) ?? ''));

    for (final e in todayEntries) {
      final startH = _parseHour(e['start_time'] as String?);
      final endH = _parseHour(e['end_time'] as String?);
      if (startH != null && endH != null) {
        if (currentHour >= startH && currentHour < endH) {
          liveClass = e;
          break;
        }
      }
    }

    if (liveClass == null) {
      for (final e in todayEntries) {
        final startH = _parseHour(e['start_time'] as String?);
        if (startH != null && startH > currentHour) {
          nextClass = e;
          break;
        }
      }
    }

    if (liveClass != null) {
      return LiquidGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.terracotta.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radio_button_checked, color: AppColors.terracotta, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('LIVE CLASS NOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${liveClass['start_time']} – ${liveClass['end_time']}',
                        style: const TextStyle(fontSize: 10, color: AppColors.inkMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    liveClass['subject_name'] ?? 'Class',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                  ),
                  Text(
                    '${liveClass['room'] ?? 'Room'} • ${liveClass['faculty_name'] ?? 'Faculty'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (nextClass != null) {
      return LiquidGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded, color: AppColors.amberDark, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amberDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('NEXT CLASS TODAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Starts at ${nextClass['start_time']}',
                        style: const TextStyle(fontSize: 10, color: AppColors.inkMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    nextClass['subject_name'] ?? 'Class',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                  ),
                  Text(
                    '${nextClass['room'] ?? 'Room'} • ${nextClass['faculty_name'] ?? 'Faculty'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // No classes scheduled today / Weekend
    return const LiquidGlassCard(
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.done_all_rounded, color: AppColors.sageDark, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No more classes scheduled for today. Check the weekly routine grid below.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.inkMuted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSkeletonWeeklyGrid(List<String> activeDays, List<int> hours) {
    const double dayColWidth = 64.0;
    const double hourColWidth = 140.0;
    const double slotHeight = 96.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowWarm,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Left Day Column
            Container(
              width: dayColWidth,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.divider, width: 1.0),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F7F5),
                      border: Border(bottom: BorderSide(color: AppColors.divider)),
                    ),
                    child: const Text(
                      'DAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final day in activeDays)
                    Container(
                      height: slotHeight,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.divider)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.substring(0, 3).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 14,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.inkMuted.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Horizontally Scrollable Grid Area with Skeletons
            Expanded(
              child: SingleChildScrollView(
                controller: _timetableScrollCtrl,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hour Header Row
                    Row(
                      children: [
                        for (final h in hours)
                          Container(
                            width: hourColWidth,
                            height: 38,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9F7F5),
                              border: Border(
                                right: BorderSide(color: AppColors.divider),
                                bottom: BorderSide(color: AppColors.divider),
                              ),
                            ),
                            child: Text(
                              _formatHourDisplay(h),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Skeleton Slot Rows
                    for (int d = 0; d < activeDays.length; d++)
                      Row(
                        children: [
                          for (int h = 0; h < hours.length; h++)
                            Container(
                              width: hourColWidth,
                              height: slotHeight,
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: AppColors.divider),
                                  bottom: BorderSide(color: AppColors.divider),
                                ),
                              ),
                              child: ((d + h) % 3 == 0)
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          SkeletonBox.text(width: 70, height: 10),
                                          SkeletonBox.text(width: 90, height: 12),
                                          SkeletonBox.text(width: 50, height: 9),
                                        ],
                                      ),
                                    )
                                  : Center(
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE5DDD5),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

