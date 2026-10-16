import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/session_model.dart';
import '../../../shared/models/holiday_model.dart';

class CalendarDayMarkerModel {
  final String date;
  final int day;
  final bool isCurrentMonth;
  final bool isToday;
  final bool hasClasses;
  final bool hasHoliday;
  final bool hasExam;
  final bool hasOther;
  final String? dominantStatus;

  CalendarDayMarkerModel({
    required this.date,
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.hasClasses,
    required this.hasHoliday,
    required this.hasExam,
    required this.hasOther,
    this.dominantStatus,
  });

  factory CalendarDayMarkerModel.fromJson(Map<String, dynamic> json) {
    return CalendarDayMarkerModel(
      date: json['date'] ?? '',
      day: json['day'] ?? 1,
      isCurrentMonth: json['is_current_month'] ?? true,
      isToday: json['is_today'] ?? false,
      hasClasses: json['has_classes'] ?? false,
      hasHoliday: json['has_holiday'] ?? false,
      hasExam: json['has_exam'] ?? false,
      hasOther: json['has_other'] ?? false,
      dominantStatus: json['dominant_status'],
    );
  }
}

enum CalendarViewMode { month, week, day }

class CalendarState {
  final int year;
  final int month;
  final String monthName;
  final int selectedDay;
  final List<CalendarDayMarkerModel> days;
  final List<ClassSessionModel> selectedDateSessions;
  final List<HolidayModel> selectedDateHolidays;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;
  final CalendarViewMode viewMode;

  CalendarState({
    required this.year,
    required this.month,
    required this.monthName,
    required this.selectedDay,
    required this.days,
    required this.selectedDateSessions,
    required this.selectedDateHolidays,
    this.isLoading = false,
    this.hasLoaded = true,
    this.errorMessage,
    this.viewMode = CalendarViewMode.month,
  });

  CalendarState copyWith({
    int? year,
    int? month,
    String? monthName,
    int? selectedDay,
    List<CalendarDayMarkerModel>? days,
    List<ClassSessionModel>? selectedDateSessions,
    List<HolidayModel>? selectedDateHolidays,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    CalendarViewMode? viewMode,
  }) {
    return CalendarState(
      year: year ?? this.year,
      month: month ?? this.month,
      monthName: monthName ?? this.monthName,
      selectedDay: selectedDay ?? this.selectedDay,
      days: days ?? this.days,
      selectedDateSessions: selectedDateSessions ?? this.selectedDateSessions,
      selectedDateHolidays: selectedDateHolidays ?? this.selectedDateHolidays,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: errorMessage,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  final ApiClient _client = ApiClient();

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  CalendarNotifier()
      : super(CalendarState(
          year: DateTime.now().year,
          month: DateTime.now().month,
          monthName: _monthNames[DateTime.now().month],
          selectedDay: DateTime.now().day,
          days: [],
          selectedDateSessions: [],
          selectedDateHolidays: [],
          isLoading: true,
          hasLoaded: false,
        )) {
    loadCalendar();
  }

  Future<void> loadCalendar({int? targetYear, int? targetMonth, int? targetDay}) async {
    if (!mounted) return;
    final y = targetYear ?? state.year;
    final m = targetMonth ?? state.month;
    final d = targetDay ?? state.selectedDay;
    final selDateStr = '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _client.dio.get(
        '${ApiEndpoints.calendar}?year=$y&month=$m&selected_date=$selDateStr',
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = resp.data;
        final dList = (data['days'] as List)
            .map((e) => CalendarDayMarkerModel.fromJson(e))
            .toList();
        final sList = (data['selected_date_sessions'] as List)
            .map((e) => ClassSessionModel.fromJson(e))
            .toList();
        final hList = data['selected_date_holidays'] != null
            ? (data['selected_date_holidays'] as List)
                .map((e) => HolidayModel.fromJson(e))
                .toList()
            : <HolidayModel>[];

        state = state.copyWith(
          year: y,
          month: m,
          monthName: data['month_name'] ?? _monthNames[m],
          selectedDay: d,
          days: dList,
          selectedDateSessions: sList,
          selectedDateHolidays: hList,
          isLoading: false,
          hasLoaded: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: 'Unable to load calendar data.',
      );
    }
  }

  void selectDay(int day) {
    if (!mounted) return;
    loadCalendar(targetDay: day);
  }

  void setViewMode(CalendarViewMode mode) {
    if (!mounted) return;
    state = state.copyWith(viewMode: mode);
  }

  void goToToday() {
    final now = DateTime.now();
    loadCalendar(targetYear: now.year, targetMonth: now.month, targetDay: now.day);
  }

  void navigatePrevious() {
    if (state.viewMode == CalendarViewMode.month) {
      changeMonth(-1);
    } else if (state.viewMode == CalendarViewMode.week) {
      final currentDt = DateTime(state.year, state.month, state.selectedDay);
      final prevWeekDt = currentDt.subtract(const Duration(days: 7));
      loadCalendar(targetYear: prevWeekDt.year, targetMonth: prevWeekDt.month, targetDay: prevWeekDt.day);
    } else {
      final currentDt = DateTime(state.year, state.month, state.selectedDay);
      final prevDayDt = currentDt.subtract(const Duration(days: 1));
      loadCalendar(targetYear: prevDayDt.year, targetMonth: prevDayDt.month, targetDay: prevDayDt.day);
    }
  }

  void navigateNext() {
    if (state.viewMode == CalendarViewMode.month) {
      changeMonth(1);
    } else if (state.viewMode == CalendarViewMode.week) {
      final currentDt = DateTime(state.year, state.month, state.selectedDay);
      final nextWeekDt = currentDt.add(const Duration(days: 7));
      loadCalendar(targetYear: nextWeekDt.year, targetMonth: nextWeekDt.month, targetDay: nextWeekDt.day);
    } else {
      final currentDt = DateTime(state.year, state.month, state.selectedDay);
      final nextDayDt = currentDt.add(const Duration(days: 1));
      loadCalendar(targetYear: nextDayDt.year, targetMonth: nextDayDt.month, targetDay: nextDayDt.day);
    }
  }

  void changeMonth(int delta) {
    var newMonth = state.month + delta;
    var newYear = state.year;
    if (newMonth < 1) {
      newMonth = 12;
      newYear -= 1;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear += 1;
    }
    loadCalendar(targetYear: newYear, targetMonth: newMonth, targetDay: 1);
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});
