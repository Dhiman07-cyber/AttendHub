import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/holiday_model.dart';

class HolidaysState {
  final bool isLoading;
  final bool hasLoaded;
  final List<HolidayModel> holidays;
  final String filterType; // "all", "upcoming", "past"
  final String? errorMessage;

  HolidaysState({
    this.isLoading = false,
    this.hasLoaded = true,
    required this.holidays,
    this.filterType = 'all',
    this.errorMessage,
  });

  List<HolidayModel> get upcomingHolidays =>
      holidays.where((h) => h.isUpcoming).toList();

  List<HolidayModel> get pastHolidays =>
      holidays.where((h) => !h.isUpcoming).toList();

  HolidaysState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    List<HolidayModel>? holidays,
    String? filterType,
    String? errorMessage,
  }) {
    return HolidaysState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      holidays: holidays ?? this.holidays,
      filterType: filterType ?? this.filterType,
      errorMessage: errorMessage,
    );
  }
}

class HolidaysNotifier extends StateNotifier<HolidaysState> {
  final ApiClient _client = ApiClient();
  final LocalStorage _storage = LocalStorage();

  HolidaysNotifier()
      : super(HolidaysState(
          isLoading: true,
          hasLoaded: false,
          holidays: [],
        )) {
    loadHolidays();
  }

  Future<void> loadHolidays() async {
    if (!mounted) return;
    final token = await _storage.getAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty || token == 'demo_token') {
      state = state.copyWith(isLoading: false, hasLoaded: true);
      return;
    }
    if (state.holidays.isEmpty) {
      final cached = await _storage.getCachedHolidays();
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        try {
          final cachedList = cached.map((e) => HolidayModel.fromJson(e)).toList();
          if (!mounted) return;
          state = state.copyWith(isLoading: false, hasLoaded: true, holidays: cachedList, errorMessage: null);
        } catch (_) {
          if (!mounted) return;
          state = state.copyWith(isLoading: true, errorMessage: null);
        }
      } else {
        if (!mounted) return;
        state = state.copyWith(isLoading: true, errorMessage: null);
      }
    } else {
      if (!mounted) return;
      state = state.copyWith(errorMessage: null);
    }

    try {
      final resp = await _client.dio.get(ApiEndpoints.holidays);
      if (!mounted) return;
      if (resp.statusCode == 200 && resp.data is List) {
        final rawList = resp.data as List;
        await _storage.saveCachedHolidays(rawList);
        if (!mounted) return;
        final list = rawList
            .map((e) => HolidayModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        state = state.copyWith(isLoading: false, hasLoaded: true, holidays: list, errorMessage: null);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: state.holidays.isEmpty ? 'Unable to load holidays from server.' : null,
      );
    }
  }

  void setFilter(String filter) {
    if (!mounted) return;
    state = state.copyWith(filterType: filter);
  }

  Future<bool> addHoliday({
    required String title,
    required String startDate,
    required String endDate,
    required String category,
    String? notes,
  }) async {
    try {
      final resp = await _client.dio.post(ApiEndpoints.holidays, data: {
        'title': title.trim(),
        'start_date': startDate,
        'end_date': endDate,
        'category': category,
        'notes': notes?.trim(),
      });
      if (!mounted) return false;
      if (resp.statusCode == 201) {
        final newHol = HolidayModel.fromJson(resp.data);
        state = state.copyWith(holidays: [...state.holidays, newHol]);
        return true;
      }
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: 'Failed to add holiday.');
    }
    return false;
  }
}

final holidaysProvider = StateNotifierProvider<HolidaysNotifier, HolidaysState>((ref) {
  return HolidaysNotifier();
});
