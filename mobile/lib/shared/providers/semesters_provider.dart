import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/local_storage.dart';
import '../models/semester_model.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/today/providers/today_provider.dart';
import '../../features/subjects/providers/subjects_provider.dart';
import '../../features/calendar/providers/calendar_provider.dart';
import '../../features/analytics/providers/analytics_provider.dart';
import '../../features/holidays/providers/holidays_provider.dart';
import '../../features/profile/providers/profile_provider.dart';

class SemestersState {
  final bool isLoading;
  final List<SemesterModel> semesters;
  final String? errorMessage;

  SemestersState({
    this.isLoading = false,
    this.semesters = const [],
    this.errorMessage,
  });

  SemesterModel? get activeSemester {
    for (final s in semesters) {
      if (s.isActive) return s;
    }
    return semesters.isNotEmpty ? semesters.last : null;
  }

  SemestersState copyWith({
    bool? isLoading,
    List<SemesterModel>? semesters,
    String? errorMessage,
  }) {
    return SemestersState(
      isLoading: isLoading ?? this.isLoading,
      semesters: semesters ?? this.semesters,
      errorMessage: errorMessage,
    );
  }
}

class SemestersNotifier extends StateNotifier<SemestersState> {
  final Ref _ref;
  final ApiClient _client = ApiClient();
  final LocalStorage _storage = LocalStorage();

  SemestersNotifier(this._ref) : super(SemestersState()) {
    _initFromCacheAndServer();
  }

  void clear() {
    state = SemestersState();
  }

  Future<void> _initFromCacheAndServer() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty || token == 'demo_token') {
      return;
    }

    try {
      final cachedStr = await _storage.getCachedSemesters();
      if (cachedStr != null && cachedStr.isNotEmpty && mounted) {
        final decoded = jsonDecode(cachedStr) as List;
        final list = decoded.map((e) => SemesterModel.fromJson(e)).toList();
        if (list.isNotEmpty) {
          state = state.copyWith(semesters: list);
        }
      }
    } catch (_) {}

    await loadSemesters();
  }

  Future<void> loadSemesters() async {
    if (!mounted) return;
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty || token == 'demo_token') {
      if (mounted) {
        state = state.copyWith(isLoading: false, semesters: const []);
      }
      return;
    }

    state = state.copyWith(isLoading: state.semesters.isEmpty, errorMessage: null);
    try {
      final resp = await _client.dio.get(ApiEndpoints.semesters);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final list = (resp.data as List)
            .map((e) => SemesterModel.fromJson(e))
            .toList();
        state = state.copyWith(isLoading: false, semesters: list);
        try {
          final jsonStr = jsonEncode(list.map((s) => s.toJson()).toList());
          await _storage.saveCachedSemesters(jsonStr);
        } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load semesters.',
      );
    }
  }

  Future<bool> switchSemester(String semesterId) async {
    if (!mounted) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _client.dio.post(
        ApiEndpoints.switchSemester,
        data: {'semester_id': semesterId},
      );
      if (!mounted) return false;
      if (resp.statusCode == 200) {
        await _storage.clearSemesterCache();
        // Refresh local semester list
        await loadSemesters();

        // Invalidate all academic and attendance context
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(selectedDateAttendanceProvider);
        _ref.invalidate(todayProvider);
        _ref.invalidate(subjectsProvider);
        _ref.invalidate(calendarProvider);
        _ref.invalidate(analyticsProvider);
        _ref.invalidate(holidaysProvider);
        _ref.invalidate(profileProvider);

        return true;
      }
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to switch semester context.',
      );
    }
    return false;
  }
}

final semestersProvider =
    StateNotifierProvider<SemestersNotifier, SemestersState>((ref) {
  return SemestersNotifier(ref);
});
