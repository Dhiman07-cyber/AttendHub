import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/session_model.dart';
import '../../../core/storage/local_storage.dart';

class TodayState {
  final bool isLoading;
  final bool isLoadingWeek;
  final bool isSaving;
  final String dateStr;
  final String semesterLabel;
  final List<ClassSessionModel> sessions;
  final double? currentOverallPercentage;
  final double? projectedOverallPercentage;
  final double projectedDelta;
  final String? successMessage;
  final String? errorMessage;

  // Weekly Timetable Grid state
  final int weekOffset;
  final String weekLabel;
  final String dateRangeDisplay;
  final String? weekStartDateStr;
  final String? weekEndDateStr;
  final List<Map<String, dynamic>> timetableEntries;
  final int classStartHour;
  final int classEndHour;
  final String startDay;
  final String endDay;
  final Map<int, Map<String, dynamic>> weeklyDayStatus;

  TodayState({
    this.isLoading = false,
    this.isLoadingWeek = false,
    this.isSaving = false,
    required this.dateStr,
    required this.semesterLabel,
    required this.sessions,
    this.currentOverallPercentage,
    this.projectedOverallPercentage,
    this.projectedDelta = 0.0,
    this.successMessage,
    this.errorMessage,
    this.weekOffset = 0,
    this.weekLabel = 'This week',
    this.dateRangeDisplay = '',
    this.weekStartDateStr,
    this.weekEndDateStr,
    this.timetableEntries = const [],
    this.classStartHour = 9,
    this.classEndHour = 17,
    this.startDay = 'Monday',
    this.endDay = 'Saturday',
    this.weeklyDayStatus = const {},
  });

  int get totalClasses => sessions.length;
  int get markedClasses => sessions.where((s) => s.attendanceStatus == 'ATTENDED' || s.attendanceStatus == 'ABSENT').length;
  int get pendingClasses => sessions.where((s) => s.attendanceStatus == null).length;
  int get notHeldClasses => sessions.where((s) => s.attendanceStatus == 'NOT_HELD').length;
  bool get isTimetableEmpty => timetableEntries.isEmpty;

  TodayState copyWith({
    bool? isLoading,
    bool? isLoadingWeek,
    bool? isSaving,
    String? dateStr,
    String? semesterLabel,
    List<ClassSessionModel>? sessions,
    double? currentOverallPercentage,
    double? projectedOverallPercentage,
    double? projectedDelta,
    String? successMessage,
    String? errorMessage,
    int? weekOffset,
    String? weekLabel,
    String? dateRangeDisplay,
    String? weekStartDateStr,
    String? weekEndDateStr,
    List<Map<String, dynamic>>? timetableEntries,
    int? classStartHour,
    int? classEndHour,
    String? startDay,
    String? endDay,
    Map<int, Map<String, dynamic>>? weeklyDayStatus,
  }) {
    return TodayState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingWeek: isLoadingWeek ?? this.isLoadingWeek,
      isSaving: isSaving ?? this.isSaving,
      dateStr: dateStr ?? this.dateStr,
      semesterLabel: semesterLabel ?? this.semesterLabel,
      sessions: sessions ?? this.sessions,
      currentOverallPercentage: currentOverallPercentage ?? this.currentOverallPercentage,
      projectedOverallPercentage: projectedOverallPercentage ?? this.projectedOverallPercentage,
      projectedDelta: projectedDelta ?? this.projectedDelta,
      successMessage: successMessage,
      errorMessage: errorMessage,
      weekOffset: weekOffset ?? this.weekOffset,
      weekLabel: weekLabel ?? this.weekLabel,
      dateRangeDisplay: dateRangeDisplay ?? this.dateRangeDisplay,
      weekStartDateStr: weekStartDateStr ?? this.weekStartDateStr,
      weekEndDateStr: weekEndDateStr ?? this.weekEndDateStr,
      timetableEntries: timetableEntries ?? this.timetableEntries,
      classStartHour: classStartHour ?? this.classStartHour,
      classEndHour: classEndHour ?? this.classEndHour,
      startDay: startDay ?? this.startDay,
      endDay: endDay ?? this.endDay,
      weeklyDayStatus: weeklyDayStatus ?? this.weeklyDayStatus,
    );
  }
}

class TodayNotifier extends StateNotifier<TodayState> {
  final ApiClient _client = ApiClient();
  int _currentRequestSeq = 0;

  TodayNotifier()
      : super(TodayState(
          dateStr: 'Today',
          semesterLabel: 'Active Semester',
          sessions: [],
          timetableEntries: const [],
          weekLabel: 'This week',
          dateRangeDisplay: _computeInitialWeekRange(),
        )) {
    loadToday();
  }

  static String _computeInitialWeekRange() {
    final range = computeWeekDateRange(0);
    return range.$3;
  }

  static String formatRelativeWeekLabel(int offset) {
    if (offset == 0) return 'This week';
    if (offset == -1) return 'Last week';
    if (offset == 1) return 'Next week';
    if (offset < -1) return '${offset.abs()} weeks ago';
    return 'In $offset weeks';
  }

  static (String start, String end, String rangeDisplay) computeWeekDateRange(int offset) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekStart = monday.add(Duration(days: offset * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startFmt = DateFormat('dd MMM yyyy').format(weekStart);
    final endFmt = DateFormat('dd MMM yyyy').format(weekEnd);
    final rangeDisplay = '$startFmt – $endFmt';
    return (startFmt, endFmt, rangeDisplay);
  }

  Future<void> setWeekOffset(int offset) async {
    if (!mounted) return;
    final range = computeWeekDateRange(offset);
    state = state.copyWith(
      weekOffset: offset,
      weekLabel: formatRelativeWeekLabel(offset),
      dateRangeDisplay: range.$3,
      weekStartDateStr: range.$1,
      weekEndDateStr: range.$2,
      isLoadingWeek: true,
      errorMessage: null,
    );
    await loadToday(offset: offset);
  }

  Future<void> loadToday({int? offset}) async {
    if (!mounted) return;
    final currentOffset = offset ?? state.weekOffset;
    final seq = ++_currentRequestSeq;
    final fallbackRange = computeWeekDateRange(currentOffset);

    // Initial load vs week update
    if (state.timetableEntries.isEmpty && state.sessions.isEmpty) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoadingWeek: true, errorMessage: null);
    }

    try {
      // 1. Fetch weekly routine with real attendance statuses from backend
      List<Map<String, dynamic>> ttEntries = [];
      String? startStr;
      String? endStr;
      String? weekLabelFromApi;
      String? dateRangeFromApi;
      String semLabel = state.semesterLabel;
      final Map<int, Map<String, dynamic>> dayStatusMap = {};

      try {
        final weeklyResp = await _client.dio.get(
          ApiEndpoints.timetableWeeklyStatus,
          queryParameters: {'week_offset': currentOffset},
        );

        if (!mounted || seq != _currentRequestSeq) return;

        if (weeklyResp.statusCode == 200 && weeklyResp.data is Map) {
          final wData = weeklyResp.data as Map<String, dynamic>;
          startStr = wData['start_date']?.toString();
          endStr = wData['end_date']?.toString();
          weekLabelFromApi = wData['week_label']?.toString();
          dateRangeFromApi = wData['date_range_label']?.toString();

          if (wData['semester_label'] != null) {
            semLabel = wData['semester_label'].toString();
          }

          final daysList = wData['days'] as List? ?? [];
          for (final dayItem in daysList) {
            final dMap = dayItem as Map<String, dynamic>;
            final dayIdx = dMap['day_of_week'] is int ? dMap['day_of_week'] as int : 0;
            final isHoliday = dMap['is_holiday'] == true;
            final isToday = dMap['is_today'] == true;
            final isPast = dMap['is_past'] == true;
            final isFuture = dMap['is_future'] == true;
            final holidayTitle = dMap['holiday_title']?.toString();

            final slotsList = dMap['slots'] as List? ?? [];
            int attendedCount = 0;

            for (final slotItem in slotsList) {
              final sMap = slotItem as Map<String, dynamic>;
              final isAttended = sMap['is_attended'] == true;
              if (isAttended) attendedCount++;

              ttEntries.add({
                'id': sMap['timetable_entry_id'],
                'timetable_entry_id': sMap['timetable_entry_id'],
                'subject_id': sMap['subject_id'],
                'subject_name': sMap['subject_name'] ?? 'Class',
                'subject_code': sMap['subject_code'],
                'subject_color': sMap['subject_color'] ?? '#C96E5B',
                'subject_icon': sMap['subject_icon'] ?? 'book',
                'day_of_week': dayIdx,
                'date': sMap['date']?.toString(),
                'start_time': sMap['start_time'] ?? '09:00',
                'end_time': sMap['end_time'] ?? '10:00',
                'room': sMap['room'] ?? '',
                'class_type': sMap['class_type'] ?? 'Theory',
                'faculty_name': sMap['faculty_name'] ?? '',
                'session_id': sMap['session_id'],
                'attendance_status': sMap['attendance_status'],
                'is_attended': isAttended,
                'is_absent': sMap['is_absent'] == true,
                'is_not_held': sMap['is_not_held'] == true,
                'is_unmarked': sMap['is_unmarked'] == true,
              });
            }

            dayStatusMap[dayIdx] = {
              'isPast': isPast,
              'isToday': isToday,
              'isFuture': isFuture,
              'isHoliday': isHoliday,
              'holidayTitle': holidayTitle,
              'total': slotsList.length,
              'attended': attendedCount,
            };
          }
        }
      } catch (_) {
        // Fallback to basic timetable entries endpoint if weekly-status has network error
        try {
          final ttResp = await _client.dio.get(ApiEndpoints.timetable);
          if (!mounted || seq != _currentRequestSeq) return;
          if (ttResp.statusCode == 200 && ttResp.data is List) {
            ttEntries = (ttResp.data as List).map((e) {
              final m = e as Map<String, dynamic>;
              return {
                'id': m['id'],
                'timetable_entry_id': m['id'],
                'subject_id': m['subject_id'],
                'subject_name': m['subject_name'] ?? 'Class',
                'subject_color': m['subject_color'] ?? '#C96E5B',
                'day_of_week': m['day_of_week'] is int ? m['day_of_week'] : 0,
                'start_time': m['start_time'] ?? '09:00',
                'end_time': m['end_time'] ?? '10:00',
                'room': m['room'] ?? '',
                'class_type': m['class_type'] ?? 'Theory',
                'faculty_name': m['faculty_name'] ?? '',
                'is_attended': false,
                'is_absent': false,
                'is_not_held': false,
                'is_unmarked': true,
              };
            }).toList();
          }
        } catch (_) {}
      }

      // If still empty, check local draft from academic setup
      if (ttEntries.isEmpty) {
        try {
          final draft = await LocalStorage().getAcademicSetupDraft('default');
          if (!mounted || seq != _currentRequestSeq) return;
          if (draft != null && draft['timetable_entries'] is List && (draft['timetable_entries'] as List).isNotEmpty) {
            ttEntries = (draft['timetable_entries'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        } catch (_) {}
      }

      // 2. Fetch today's classes
      List<ClassSessionModel> list = [];
      String dateStr = state.dateStr;
      double? currentPct;

      try {
        final resp = await _client.dio.get(ApiEndpoints.todayAttendance);
        if (!mounted || seq != _currentRequestSeq) return;
        if (resp.statusCode == 200 && resp.data is Map) {
          final data = resp.data as Map<String, dynamic>;
          list = (data['sessions'] as List? ?? [])
              .map((e) => ClassSessionModel.fromJson(e))
              .toList();
          currentPct = (data['current_overall_percentage'] as num?)?.toDouble();
          dateStr = data['selected_date_str'] ?? dateStr;
          if (data['semester_label'] != null) {
            semLabel = data['semester_label'].toString();
          }
        }
      } catch (_) {}

      // Calculate schedule range
      int minHour = 9;
      int maxHour = 17;
      if (ttEntries.isNotEmpty) {
        for (final e in ttEntries) {
          final st = e['start_time'] as String?;
          final et = e['end_time'] as String?;
          if (st != null && st.contains(':')) {
            final h = int.tryParse(st.split(':')[0]);
            if (h != null && h < minHour) minHour = h;
          }
          if (et != null && et.contains(':')) {
            final h = int.tryParse(et.split(':')[0]);
            if (h != null && h > maxHour) maxHour = h;
          }
        }
      }

      if (!mounted || seq != _currentRequestSeq) return;

      final finalWeekLabel = weekLabelFromApi ?? formatRelativeWeekLabel(currentOffset);
      final finalRangeDisplay = dateRangeFromApi ?? fallbackRange.$3;

      state = state.copyWith(
        isLoading: false,
        isLoadingWeek: false,
        weekOffset: currentOffset,
        weekLabel: finalWeekLabel,
        dateRangeDisplay: finalRangeDisplay,
        weekStartDateStr: startStr ?? fallbackRange.$1,
        weekEndDateStr: endStr ?? fallbackRange.$2,
        dateStr: dateStr,
        semesterLabel: semLabel,
        sessions: list,
        currentOverallPercentage: currentPct,
        projectedOverallPercentage: currentPct,
        projectedDelta: 0.0,
        timetableEntries: ttEntries,
        classStartHour: minHour,
        classEndHour: maxHour,
        weeklyDayStatus: dayStatusMap,
      );
    } catch (e) {
      if (!mounted || seq != _currentRequestSeq) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingWeek: false,
        errorMessage: 'Unable to load schedule from server.',
      );
    }
  }
}

final todayProvider = StateNotifierProvider<TodayNotifier, TodayState>((ref) {
  return TodayNotifier();
});
