import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/landscape_header.dart';
import '../../shared/widgets/liquid_glass_card.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import 'providers/calendar_provider.dart';
import '../../shared/providers/semesters_provider.dart';

class CalendarScreen extends ConsumerWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onNavigateToHolidays;
  final VoidCallback? onNavigateToProfile;

  const CalendarScreen({
    super.key,
    required this.onOpenDrawer,
    required this.onNavigateToHolidays,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final semState = ref.watch(semestersProvider);

    if ((!state.hasLoaded || state.isLoading) && state.days.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildCalendarSkeleton(context),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            LandscapeHeaderWidget(
              greeting: 'Calendar',
              userName: 'Attendance & Events',
              semesterInfo:
                  '${semState.activeSemester?.label ?? 'Active Semester'} • Schedule',
              showActions: false,
              topOffset: 76,
            ),

            const SizedBox(height: 18),

            // Mode Tabs: Month | Week | Day + Today button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EBE6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildViewPill(
                          label: 'Month',
                          isActive: state.viewMode == CalendarViewMode.month,
                          onTap: () => ref
                              .read(calendarProvider.notifier)
                              .setViewMode(CalendarViewMode.month),
                        ),
                        _buildViewPill(
                          label: 'Week',
                          isActive: state.viewMode == CalendarViewMode.week,
                          onTap: () => ref
                              .read(calendarProvider.notifier)
                              .setViewMode(CalendarViewMode.week),
                        ),
                        _buildViewPill(
                          label: 'Day',
                          isActive: state.viewMode == CalendarViewMode.day,
                          onTap: () => ref
                              .read(calendarProvider.notifier)
                              .setViewMode(CalendarViewMode.day),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        ref.read(calendarProvider.notifier).goToToday(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Calendar Card (Month, Week, or Day View with interactive swipe navigation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RepaintBoundary(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -150) {
                        ref.read(calendarProvider.notifier).navigateNext();
                      } else if (details.primaryVelocity! > 150) {
                        ref.read(calendarProvider.notifier).navigatePrevious();
                      }
                    }
                  },
                  child: LiquidGlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                  children: [
                    // Navigator Row (Chevrons + Current View Label)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () => ref
                              .read(calendarProvider.notifier)
                              .navigatePrevious(),
                        ),
                        Text(
                          state.viewMode == CalendarViewMode.day
                              ? '${state.selectedDay} ${state.monthName} ${state.year}'
                              : state.viewMode == CalendarViewMode.week
                                  ? 'Week of ${state.selectedDay} ${state.monthName}'
                                  : '${state.monthName} ${state.year}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () => ref
                              .read(calendarProvider.notifier)
                              .navigateNext(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (state.viewMode == CalendarViewMode.month) ...[
                      // Day of Week Header: Sun Mon Tue Wed Thu Fri Sat
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          'Sun',
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat'
                        ].map((d) {
                          return SizedBox(
                            width: 38,
                            child: Text(
                              d,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkMuted),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 8),

                      // Dynamic Days Grid
                      Builder(builder: (context) {
                        final firstWeekday =
                            DateTime(state.year, state.month, 1).weekday;
                        final offset =
                            firstWeekday == 7 ? 0 : firstWeekday;
                        final daysInMonth =
                            DateTime(state.year, state.month + 1, 0).day;
                        final prevMonthDays =
                            DateTime(state.year, state.month, 0).day;
                        final totalSlots =
                            ((offset + daysInMonth + 6) ~/ 7) * 7;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: totalSlots,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 0.95,
                          ),
                          itemBuilder: (context, index) {
                            if (index < offset) {
                              final prevDay =
                                  prevMonthDays - offset + index + 1;
                              return Center(
                                child: Text(
                                  '$prevDay',
                                  style: const TextStyle(
                                      color: Color(0xFFC7C2BE), fontSize: 13),
                                ),
                              );
                            }

                            final dayNum = index - offset + 1;
                            if (dayNum > daysInMonth) {
                              final nextDay = dayNum - daysInMonth;
                              return Center(
                                child: Text(
                                  '$nextDay',
                                  style: const TextStyle(
                                      color: Color(0xFFC7C2BE), fontSize: 13),
                                ),
                              );
                            }

                            final isSelected = dayNum == state.selectedDay;
                            final dayMarker = state.days.firstWhere(
                              (d) => d.day == dayNum,
                              orElse: () => CalendarDayMarkerModel(
                                date: '',
                                day: dayNum,
                                isCurrentMonth: true,
                                isToday: false,
                                hasClasses: false,
                                hasHoliday: false,
                                hasExam: false,
                                hasOther: false,
                              ),
                            );

                            return GestureDetector(
                              onTap: () => ref
                                  .read(calendarProvider.notifier)
                                  .selectDay(dayNum),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE9938B)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Dots indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (dayMarker.hasClasses)
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: const BoxDecoration(
                                              color: AppColors.sage,
                                              shape: BoxShape.circle),
                                        ),
                                      if (dayMarker.hasHoliday)
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: const BoxDecoration(
                                              color: AppColors.coral,
                                              shape: BoxShape.circle),
                                        ),
                                      if (dayMarker.hasExam)
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: const BoxDecoration(
                                              color: AppColors.ocean,
                                              shape: BoxShape.circle),
                                        ),
                                      if (dayMarker.hasOther)
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: const BoxDecoration(
                                              color: AppColors.amber,
                                              shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                    ] else if (state.viewMode == CalendarViewMode.week) ...[
                      _buildWeekView(context, ref, state),
                    ] else ...[
                      _buildDayView(context, ref, state),
                    ],

                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 10),

                    // Legend: Class, Holiday, Exam, Other
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(AppColors.sage, 'Class'),
                        _buildLegendItem(AppColors.coral, 'Holiday'),
                        _buildLegendItem(AppColors.ocean, 'Exam'),
                        _buildLegendItem(AppColors.amber, 'Other'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

            const SizedBox(height: 16),

            // Events on Selected Date Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(builder: (context) {
                final selDt =
                    DateTime(state.year, state.month, state.selectedDay);
                final weekdayNames = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun'
                ];
                final weekdayStr = weekdayNames[selDt.weekday - 1];
                final monthAbbr = state.monthName.length >= 3
                    ? state.monthName.substring(0, 3)
                    : state.monthName;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Events on $weekdayStr, ${state.selectedDay} $monthAbbr ${state.year}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.coralLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.selectedDateSessions.length} events',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.coral),
                      ),
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 10),

            // Detailed Sessions List
            if (state.selectedDateSessions.isEmpty &&
                state.selectedDateHolidays.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(
                    child: Text(
                      'No classes or events scheduled for this day',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.selectedDateSessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = state.selectedDateSessions[index];
                    return RepaintBoundary(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.sage,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${s.startTime} – ${s.endTime}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.getSubjectColor(s.subjectColor)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              s.subjectIcon == 'code'
                                  ? Icons.code_rounded
                                  : s.subjectIcon == 'settings'
                                      ? Icons.settings_rounded
                                      : Icons.functions_rounded,
                              size: 16,
                              color:
                                  AppColors.getSubjectColor(s.subjectColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.subjectName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                Text(
                                  '${s.facultyName ?? ''} • ${s.room ?? 'Room 101'}',
                                  style: AppTypography.bodySmall
                                      .copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.inkMuted),
                        ],
                      ),
                    ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Bottom Buttons: Add Event & View Holidays (IntrinsicHeight for exact matching height)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add,
                            color: AppColors.terracotta, size: 18),
                        label: const Text('Add Event',
                            style: TextStyle(
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.w700)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Custom calendar events enabled.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.terracotta, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_note_outlined,
                            color: AppColors.ink, size: 18),
                        label: const Text('View Holidays',
                            style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700)),
                        onPressed: onNavigateToHolidays,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.divider, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                        ),
                      ),
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

  Widget _buildWeekView(
      BuildContext context, WidgetRef ref, CalendarState state) {
    final selDt = DateTime(state.year, state.month, state.selectedDay);
    final diff = selDt.weekday == 7 ? 0 : selDt.weekday;
    final startOfWeek = selDt.subtract(Duration(days: diff));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final dayDt = startOfWeek.add(Duration(days: i));
        final isSelected = dayDt.day == state.selectedDay &&
            dayDt.month == state.month &&
            dayDt.year == state.year;
        final weekdayLabel =
            ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][i];
        final dayMarker = state.days.firstWhere(
          (d) => d.day == dayDt.day && dayDt.month == state.month,
          orElse: () => CalendarDayMarkerModel(
            date: '',
            day: dayDt.day,
            isCurrentMonth: dayDt.month == state.month,
            isToday: false,
            hasClasses: false,
            hasHoliday: false,
            hasExam: false,
            hasOther: false,
          ),
        );

        return GestureDetector(
          onTap: () {
            ref.read(calendarProvider.notifier).loadCalendar(
                  targetYear: dayDt.year,
                  targetMonth: dayDt.month,
                  targetDay: dayDt.day,
                );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFDEAE8) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.terracotta.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekdayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.terracotta
                        : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.terracotta : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${dayDt.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dayMarker.hasClasses)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                            color: AppColors.sage, shape: BoxShape.circle),
                      ),
                    if (dayMarker.hasHoliday)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                            color: AppColors.coral, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayView(
      BuildContext context, WidgetRef ref, CalendarState state) {
    final dateObj = DateTime(state.year, state.month, state.selectedDay);
    final weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final weekday = weekdayNames[dateObj.weekday - 1];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${state.selectedDay}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.terracotta,
                  ),
                ),
                Text(
                  state.monthName.length >= 3
                      ? state.monthName.substring(0, 3).toUpperCase()
                      : state.monthName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${state.selectedDateSessions.length} Classes scheduled',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSkeleton(BuildContext context) {
    return const ShimmerLoading(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LandscapeHeaderWidget(
              greeting: 'Calendar',
              userName: '',
              semesterInfo: '',
              isLoading: true,
              showActions: false,
              topOffset: 76,
            ),
            SizedBox(height: 18),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(
                      width: 180,
                      height: 32,
                      borderRadius: BorderRadius.all(Radius.circular(16))),
                  SkeletonBox(
                      width: 60,
                      height: 32,
                      borderRadius: BorderRadius.all(Radius.circular(14))),
                ],
              ),
            ),
            SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LiquidGlassCard(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonBox.circle(size: 32),
                        SkeletonBox.text(width: 120, height: 16),
                        SkeletonBox.circle(size: 32),
                      ],
                    ),
                    SizedBox(height: 16),
                    SkeletonBox(
                        height: 180,
                        borderRadius: BorderRadius.all(Radius.circular(12))),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SkeletonBox(
                      height: 52,
                      borderRadius: BorderRadius.all(Radius.circular(14))),
                  SizedBox(height: 10),
                  SkeletonBox(
                      height: 52,
                      borderRadius: BorderRadius.all(Radius.circular(14))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFDEAE8) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.terracotta : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
      ],
    );
  }
}
