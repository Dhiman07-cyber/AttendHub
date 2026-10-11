import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/user_model.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final UserModel? user;

  AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _client = ApiClient();
  final LocalStorage _storage = LocalStorage();

  AuthNotifier() : super(AuthState(isAuthenticated: false, isLoading: true)) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final token = await _storage.getAccessToken();
    final cachedUser = await _storage.getCachedUser();

    if (token == null || token.isEmpty || token == 'demo_token') {
      await _storage.clearAuth();
      state = AuthState(isAuthenticated: false, isLoading: false);
      return;
    }

    // Immediately restore cached session so there is zero flash of login/onboarding screen
    if (cachedUser != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: cachedUser,
      );
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final resp = await _client.dio.get(ApiEndpoints.me);
      if (resp.statusCode == 200) {
        final user = UserModel.fromJson(resp.data);
        await _storage.saveUser(user);
        await _storage.setOnboarded(true);
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: user,
        );
      }
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 401) {
        // Access token rejected and refresh interceptor could not refresh
        await _storage.clearAuth();
        state = AuthState(isAuthenticated: false, isLoading: false);
      } else {
        // Network timeout / connection error / server starting up:
        // Preserve user state if cached user exists
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _client.dio.post(
        ApiEndpoints.login,
        data: {'email': email.trim(), 'password': password},
      );
      final data = resp.data;
      await _storage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      final user = UserModel(
        id: data['user_id'],
        email: data['email'],
        fullName: data['full_name'],
        avatarInitial: data['full_name'].isNotEmpty ? data['full_name'][0].toUpperCase() : 'A',
        isActive: true,
      );
      await _storage.saveUser(user);
      await _storage.setOnboarded(true);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
      return true;
    } catch (e) {
      String msg = 'Invalid email or password.';
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['detail'] != null) {
          msg = e.response!.data['detail'].toString();
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          msg = "Couldn't connect to server. Check your connection.";
        }
      }
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? universityName,
    String? courseName,
    int? semesterNumber,
    bool seedDemoData = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _client.dio.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim(),
          'university_name': universityName,
          'course_name': courseName,
          'current_semester_number': semesterNumber ?? 1,
          'seed_demo_data': seedDemoData,
        },
      );
      final data = resp.data;
      await _storage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      final user = UserModel(
        id: data['user_id'],
        email: data['email'],
        fullName: data['full_name'],
        avatarInitial: data['full_name'].isNotEmpty ? data['full_name'][0].toUpperCase() : 'A',
        isActive: true,
      );
      await _storage.saveUser(user);
      await _storage.setOnboarded(true);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
      return true;
    } catch (e) {
      String msg = 'Registration failed. Please check your information.';
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['detail'] != null) {
          msg = e.response!.data['detail'].toString();
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          msg = "Couldn't connect to server. Check your connection.";
        }
      }
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await _storage.clearAuth();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
