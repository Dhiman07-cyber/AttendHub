import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/models/holiday_model.dart';

class HolidaysState {
  final bool isLoading;
  final List<HolidayModel> holidays;
  final String filterType; // "all", "upcoming", "past"
  final String? errorMessage;

  HolidaysState({
    this.isLoading = false,
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
    List<HolidayModel>? holidays,
    String? filterType,
    String? errorMessage,
  }) {
    return HolidaysState(
      isLoading: isLoading ?? this.isLoading,
      holidays: holidays ?? this.holidays,
      filterType: filterType ?? this.filterType,
      errorMessage: errorMessage,
    );
  }
}

class HolidaysNotifier extends StateNotifier<HolidaysState> {
  final ApiClient _client = ApiClient();

  HolidaysNotifier()
      : super(HolidaysState(
          holidays: [],
        )) {
    loadHolidays();
  }

  Future<void> loadHolidays() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _client.dio.get(ApiEndpoints.holidays);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final list = (resp.data as List)
            .map((e) => HolidayModel.fromJson(e))
            .toList();
        state = state.copyWith(isLoading: false, holidays: list);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load holidays from server.',
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
