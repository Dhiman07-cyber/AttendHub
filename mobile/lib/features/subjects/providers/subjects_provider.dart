import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
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

  SubjectsNotifier()
      : super(SubjectsState(
          subjects: [],
        )) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _client.dio.get(ApiEndpoints.subjects);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final list = (resp.data as List)
            .map((e) => SubjectModel.fromJson(e))
            .toList();
        state = state.copyWith(isLoading: false, subjects: list);
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load subjects from server.',
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

  Future<bool> archiveSubject(String id) async {
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
      state = state.copyWith(errorMessage: 'Failed to archive subject.');
    }
    return false;
  }
}

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, SubjectsState>((ref) {
  return SubjectsNotifier();
});
