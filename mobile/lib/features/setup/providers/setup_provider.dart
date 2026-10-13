import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../today/providers/today_provider.dart';
import '../../subjects/providers/subjects_provider.dart';
import '../../calendar/providers/calendar_provider.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../holidays/providers/holidays_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../shared/providers/semesters_provider.dart';

class SetupStatusModel {
  final bool isProfileComplete;
  final bool hasActiveSemester;
  final bool isSemesterConfigured;
  final bool setupComplete;
  final String? currentSemesterId;
  final String? currentSemesterLabel;
  final int subjectCount;

  const SetupStatusModel({
    required this.isProfileComplete,
    required this.hasActiveSemester,
    required this.isSemesterConfigured,
    required this.setupComplete,
    this.currentSemesterId,
    this.currentSemesterLabel,
    this.subjectCount = 0,
  });

  factory SetupStatusModel.fromJson(Map<String, dynamic> json) {
    return SetupStatusModel(
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      hasActiveSemester: json['has_active_semester'] as bool? ?? false,
      isSemesterConfigured: json['is_semester_configured'] as bool? ?? false,
      setupComplete: json['setup_complete'] as bool? ?? false,
      currentSemesterId: json['current_semester_id'] as String?,
      currentSemesterLabel: json['current_semester_label'] as String?,
      subjectCount: (json['subject_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SetupState {
  final bool isLoading;
  final SetupStatusModel? status;
  final String? errorMessage;

  const SetupState({
    this.isLoading = false,
    this.status,
    this.errorMessage,
  });

  SetupState copyWith({
    bool? isLoading,
    SetupStatusModel? status,
    String? errorMessage,
  }) {
    return SetupState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class SetupNotifier extends StateNotifier<SetupState> {
  final Ref _ref;
  final ApiClient _client = ApiClient();
  final LocalStorage _storage = LocalStorage();

  SetupNotifier(this._ref) : super(const SetupState()) {
    _restoreCachedStatus();
  }

  Future<void> _restoreCachedStatus() async {
    try {
      final cached = await _storage.getCachedSetupStatus();
      if (cached != null && mounted && state.status == null) {
        state = state.copyWith(status: SetupStatusModel.fromJson(cached));
      }
    } catch (_) {}
  }

  Future<SetupStatusModel?> checkStatus() async {
    if (!mounted) return null;
    if (state.status == null) {
      try {
        final cached = await _storage.getCachedSetupStatus();
        if (cached != null && mounted) {
          state = state.copyWith(status: SetupStatusModel.fromJson(cached));
        }
      } catch (_) {}
    }
    if (!mounted) return null;
    state = state.copyWith(isLoading: state.status == null, errorMessage: null);
    try {
      final resp = await _client.dio.get(ApiEndpoints.setupStatus);
      if (!mounted) return null;
      if (resp.statusCode == 200 && resp.data is Map) {
        final map = Map<String, dynamic>.from(resp.data as Map);
        final model = SetupStatusModel.fromJson(map);
        await _storage.saveCachedSetupStatus(map);
        if (!mounted) return model;
        state = state.copyWith(isLoading: false, status: model, errorMessage: null);
        return model;
      }
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.status == null
            ? 'Unable to verify academic setup status.'
            : null,
      );
    }
    return state.status;
  }

  Future<Map<String, dynamic>?> fetchSetupData({int? semesterNumber}) async {
    try {
      final uri = semesterNumber != null
          ? '${ApiEndpoints.setupData}?semester_number=$semesterNumber'
          : ApiEndpoints.setupData;
      final resp = await _client.dio.get(uri);
      if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
        return resp.data as Map<String, dynamic>;
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  Future<bool> commitSetup(Map<String, dynamic> payload) async {
    if (!mounted) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _client.dio.post(ApiEndpoints.setup, data: payload);
      if (!mounted) return false;
      if (resp.statusCode == 200) {
        await _storage.clearSemesterCache();
        // Reload status
        await checkStatus();

        // Invalidate all dependent providers
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(selectedDateAttendanceProvider);
        _ref.invalidate(todayProvider);
        _ref.invalidate(subjectsProvider);
        _ref.invalidate(calendarProvider);
        _ref.invalidate(analyticsProvider);
        _ref.invalidate(holidaysProvider);
        _ref.invalidate(profileProvider);
        _ref.invalidate(semestersProvider);

        return true;
      }
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to commit academic setup. Please review entries.',
      );
    }
    return false;
  }
}

final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  return SetupNotifier(ref);
});
