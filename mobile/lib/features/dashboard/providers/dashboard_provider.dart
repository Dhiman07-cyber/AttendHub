import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/dashboard_model.dart';
import '../../../shared/models/session_model.dart';
import '../../../shared/providers/semesters_provider.dart';
import '../../today/providers/today_provider.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../calendar/providers/calendar_provider.dart';
import '../../subjects/providers/subjects_provider.dart';

final dashboardProvider = FutureProvider<DashboardOverviewModel>((ref) async {
  ref.watch(semestersProvider);
  final client = ApiClient();
  final response = await client.dio.get(ApiEndpoints.dashboard);
  if (response.statusCode == 200) {
    return DashboardOverviewModel.fromJson(response.data);
  }
  throw Exception('Failed to load dashboard: ${response.statusCode}');
});

class SelectedDateAttendanceState {
  final DateTime selectedDate;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isHoliday;
  final String? holidayName;
  final List<ClassSessionModel> sessions;
  final Map<String, String> draftMarks; // slotKey -> ATTENDED | ABSENT | NOT_HELD
  final bool isEditable;
  final bool isFuture;
  final bool isExpired;
  final bool hasTimetableSetup;

  SelectedDateAttendanceState({
    required this.selectedDate,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isHoliday = false,
    this.holidayName,
    this.sessions = const [],
    this.draftMarks = const {},
    required this.isEditable,
    required this.isFuture,
    required this.isExpired,
    this.hasTimetableSetup = true,
  });

  String get dateIso =>
      '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

  SelectedDateAttendanceState copyWith({
    DateTime? selectedDate,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isHoliday,
    String? holidayName,
    List<ClassSessionModel>? sessions,
    Map<String, String>? draftMarks,
    bool? isEditable,
    bool? isFuture,
    bool? isExpired,
    bool? hasTimetableSetup,
  }) {
    return SelectedDateAttendanceState(
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isHoliday: isHoliday ?? this.isHoliday,
      holidayName: holidayName ?? this.holidayName,
      sessions: sessions ?? this.sessions,
      draftMarks: draftMarks ?? this.draftMarks,
      isEditable: isEditable ?? this.isEditable,
      isFuture: isFuture ?? this.isFuture,
      isExpired: isExpired ?? this.isExpired,
      hasTimetableSetup: hasTimetableSetup ?? this.hasTimetableSetup,
    );
  }
}

class SelectedDateAttendanceNotifier extends StateNotifier<SelectedDateAttendanceState> {
  final Ref? _ref;
  final ApiClient _client;
  final LocalStorage _storage;

  SelectedDateAttendanceNotifier([
    this._ref,
    ApiClient? client,
    LocalStorage? storage,
    bool loadOnInit = true,
  ])  : _client = client ?? ApiClient(),
        _storage = storage ?? LocalStorage(),
        super(_initialState()) {
    if (loadOnInit && _ref != null) {
      loadDaySessions();
    }
  }

  static SelectedDateAttendanceState _initialState() {
    final now = DateTime.now();
    final win = _evaluateEditWindow(now);
    return SelectedDateAttendanceState(
      selectedDate: now,
      isEditable: win.isEditable,
      isFuture: win.isFuture,
      isExpired: win.isExpired,
    );
  }

  static ({bool isEditable, bool isFuture, bool isExpired}) _evaluateEditWindow(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);
    final diffDays = today.difference(targetDay).inDays;

    if (diffDays < 0) {
      return (isEditable: false, isFuture: true, isExpired: false);
    } else if (diffDays > 2) {
      return (isEditable: false, isFuture: false, isExpired: true);
    } else {
      return (isEditable: true, isFuture: false, isExpired: false);
    }
  }

  String _getSlotKey(ClassSessionModel s) {
    if (s.timetableEntryId != null && s.timetableEntryId!.isNotEmpty) {
      return s.timetableEntryId!;
    }
    return s.id;
  }

  Future<void> changeDate(DateTime newDate) async {
    if (!mounted) return;
    final win = _evaluateEditWindow(newDate);
    state = state.copyWith(
      selectedDate: newDate,
      isEditable: win.isEditable,
      isFuture: win.isFuture,
      isExpired: win.isExpired,
      isLoading: true,
      errorMessage: null,
    );
    await loadDaySessions();
  }

  Future<void> selectDate(DateTime newDate) async {
    await changeDate(newDate);
  }

  Future<void> goToPreviousDay() async {
    await changeDate(state.selectedDate.subtract(const Duration(days: 1)));
  }

  Future<void> goToNextDay() async {
    await changeDate(state.selectedDate.add(const Duration(days: 1)));
  }

  Future<void> goToToday() async {
    await changeDate(DateTime.now());
  }

  Future<void> loadDaySessions() async {
    if (!mounted || _ref == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dateStr = state.dateIso;
      final semState = _ref.read(semestersProvider);
      final activeSemId = semState.activeSemester?.id ?? '';
      final cachedUser = await _storage.getCachedUser();
      if (!mounted) return;
      final userId = cachedUser?.id ?? 'default';

      // 1. Fetch server state for this calendar date
      final resp = await _client.dio.get(
        ApiEndpoints.dayAttendance,
        queryParameters: {'date': dateStr},
      );
      if (!mounted) return;

      List<ClassSessionModel> sessions = [];
      bool isHoliday = false;
      String? holidayName;

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        isHoliday = data['is_holiday'] == true;
        holidayName = data['holiday_name'] as String?;
        final rawSessions = data['sessions'] as List? ?? [];
        sessions = rawSessions
            .map((e) => ClassSessionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Check if timetable is configured
      bool hasTimetable = true;
      if (sessions.isEmpty && !isHoliday) {
        // If today has 0 sessions, verify if semester has any timetable entries at all
        try {
          final ttResp = await _client.dio.get(ApiEndpoints.timetableWeeklyStatus);
          if (!mounted) return;
          if (ttResp.statusCode == 200 && ttResp.data != null) {
            final days = ttResp.data['days'] as List? ?? [];
            int totalWeeklySlots = 0;
            for (final d in days) {
              final slots = d['slots'] as List? ?? [];
              totalWeeklySlots += slots.length;
            }
            hasTimetable = totalWeeklySlots > 0;
          }
        } catch (_) {}
      }

      // 2. Load persistent local draft
      final savedDraft = await _storage.getAttendanceDraft(
        userId: userId,
        semesterId: activeSemId,
        date: dateStr,
      );
      if (!mounted) return;

      final Map<String, String> marks = {};
      // Initialize with saved database attendance if available
      for (final s in sessions) {
        final k = _getSlotKey(s);
        if (s.attendanceStatus != null) {
          marks[k] = s.attendanceStatus!;
        }
      }

      // Overlay user's pending local draft
      if (savedDraft != null) {
        marks.addAll(savedDraft);
      }

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        sessions: sessions,
        isHoliday: isHoliday,
        holidayName: holidayName,
        draftMarks: marks,
        hasTimetableSetup: hasTimetable,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void toggleAttended(ClassSessionModel session) {
    if (!mounted || !state.isEditable) return;
    final k = _getSlotKey(session);
    final updated = Map<String, String>.from(state.draftMarks);

    if (updated[k] == 'ATTENDED') {
      updated.remove(k);
    } else {
      updated[k] = 'ATTENDED';
    }

    if (!mounted) return;
    state = state.copyWith(draftMarks: updated);
    _persistDraft(updated);
  }

  void markNotHeld(ClassSessionModel session) {
    if (!mounted || !state.isEditable) return;
    final k = _getSlotKey(session);
    final updated = Map<String, String>.from(state.draftMarks);

    if (updated[k] == 'NOT_HELD') {
      updated.remove(k);
    } else {
      updated[k] = 'NOT_HELD';
    }

    if (!mounted) return;
    state = state.copyWith(draftMarks: updated);
    _persistDraft(updated);
  }

  Future<void> _persistDraft(Map<String, String> marks) async {
    if (!mounted || _ref == null) return;
    final semState = _ref.read(semestersProvider);
    final activeSemId = semState.activeSemester?.id ?? '';
    final cachedUser = await _storage.getCachedUser();
    if (!mounted) return;
    final userId = cachedUser?.id ?? 'default';

    await _storage.saveAttendanceDraft(
      userId: userId,
      semesterId: activeSemId,
      date: state.dateIso,
      marks: marks,
    );
  }

  Future<bool> confirmAndSaveAttendance() async {
    if (!mounted || _ref == null || !state.isEditable || state.sessions.isEmpty) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final records = <Map<String, dynamic>>[];
      for (final s in state.sessions) {
        final k = _getSlotKey(s);
        // Checked ATTENDED -> ATTENDED
        // Explicit NOT_HELD -> NOT_HELD
        // Unchecked eligible -> ABSENT
        final status = state.draftMarks[k] ?? 'ABSENT';
        records.add({
          'timetable_entry_id': s.timetableEntryId,
          'subject_id': s.subjectId,
          'status': status,
        });
      }

      final payload = {
        'date': state.dateIso,
        'records': records,
      };

      final resp = await _client.dio.post(
        ApiEndpoints.bulkDayAttendance,
        data: payload,
      );
      if (!mounted) return false;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Clear matching local draft
        final semState = _ref.read(semestersProvider);
        final activeSemId = semState.activeSemester?.id ?? '';
        final cachedUser = await _storage.getCachedUser();
        if (!mounted) return true;
        final userId = cachedUser?.id ?? 'default';

        await _storage.clearAttendanceDraft(
          userId: userId,
          semesterId: activeSemId,
          date: state.dateIso,
        );
        if (!mounted) return true;

        // Invalidate dependent providers across the app
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(todayProvider);
        _ref.invalidate(analyticsProvider);
        _ref.invalidate(calendarProvider);
        _ref.invalidate(subjectsProvider);

        // Reload sessions to reflect persisted records
        await loadDaySessions();
        if (mounted) {
          state = state.copyWith(isSaving: false);
        }
        return true;
      } else {
        throw Exception('Failed to save attendance: ${resp.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: e.toString(),
        );
      }
      return false;
    }
  }
}

final selectedDateAttendanceProvider = StateNotifierProvider.autoDispose<
    SelectedDateAttendanceNotifier, SelectedDateAttendanceState>((ref) {
  return SelectedDateAttendanceNotifier(ref);
});

