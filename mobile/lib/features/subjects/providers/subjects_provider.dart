import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/subject_model.dart';

class SubjectsState {
  final bool isLoading;
  final List<SubjectModel> subjects;
  final String searchQuery;
  final bool showInactive;
  final String? errorMessage;

  SubjectsState({
    this.isLoading = false,
    required this.subjects,
    this.searchQuery = '',
    this.showInactive = false,
    this.errorMessage,
  });

  List<SubjectModel> get filteredSubjects {
    return subjects.where((s) {
      if (!showInactive && !s.isActive) return false;
      if (searchQuery.isNotEmpty &&
          !s.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  SubjectsState copyWith({
    bool? isLoading,
    List<SubjectModel>? subjects,
    String? searchQuery,
    bool? showInactive,
    String? errorMessage,
  }) {
    return SubjectsState(
      isLoading: isLoading ?? this.isLoading,
      subjects: subjects ?? this.subjects,
      searchQuery: searchQuery ?? this.searchQuery,
      showInactive: showInactive ?? this.showInactive,
      errorMessage: errorMessage,
    );
  }
}

class SubjectsNotifier extends StateNotifier<SubjectsState> {
  final ApiClient _client = ApiClient();
  final LocalStorage _storage = LocalStorage();

  SubjectsNotifier()
      : super(SubjectsState(
          subjects: [],
        )) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    if (!mounted) return;
    if (state.subjects.isEmpty) {
      final cached = await _storage.getCachedSubjects();
      if (!mounted) return;
      if (cached != null && cached.isNotEmpty) {
        try {
          final cachedList = cached.map((e) => SubjectModel.fromJson(e)).toList();
          state = state.copyWith(isLoading: false, subjects: cachedList, errorMessage: null);
        } catch (_) {
          state = state.copyWith(isLoading: true, errorMessage: null);
        }
      } else {
        state = state.copyWith(isLoading: true, errorMessage: null);
      }
    } else {
      state = state.copyWith(errorMessage: null);
    }

    try {
      final resp = await _client.dio.get(ApiEndpoints.subjects);
      if (!mounted) return;
      if (resp.statusCode == 200 && resp.data is List) {
        final rawList = resp.data as List;
        await _storage.saveCachedSubjects(rawList);
        if (!mounted) return;
        final list = rawList
            .map((e) => SubjectModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        state = state.copyWith(isLoading: false, subjects: list, errorMessage: null);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: state.subjects.isEmpty ? 'Unable to load subjects from server.' : null,
      );
    }
  }

  void setSearchQuery(String query) {
    if (!mounted) return;
    state = state.copyWith(searchQuery: query);
  }

  void toggleFilter(bool showInactive) {
    if (!mounted) return;
    state = state.copyWith(showInactive: showInactive);
  }

  Future<bool> addSubject(String name, String? code, String? faculty, String color, String icon) async {
    try {
      final resp = await _client.dio.post(ApiEndpoints.subjects, data: {
        'name': name.trim(),
        'code': code?.trim(),
        'faculty_name': faculty?.trim(),
        'color': color,
        'icon': icon,
      });
      if (!mounted) return false;
      if (resp.statusCode == 201) {
        final newSub = SubjectModel.fromJson(resp.data);
        state = state.copyWith(subjects: [...state.subjects, newSub]);
        return true;
      }
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: 'Failed to create subject.');
    }
    return false;
  }

  Future<bool> deleteSubject(String id) async {
    try {
      final resp = await _client.dio.delete('${ApiEndpoints.subjects}/$id');
      if (!mounted) return false;
      if (resp.statusCode == 200) {
        state = state.copyWith(
          subjects: state.subjects.map((s) {
            if (s.id == id) {
              return s.copyWith(isActive: false);
            }
            return s;
          }).toList(),
        );
        return true;
      }
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: 'Failed to delete subject.');
    }
    return false;
  }

  Future<bool> archiveSubject(String id) => deleteSubject(id);
}

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, SubjectsState>((ref) {
  return SubjectsNotifier();
});
