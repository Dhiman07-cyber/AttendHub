import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../shared/models/user_model.dart';
import '../../profile/providers/profile_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../setup/providers/setup_provider.dart';
import '../../today/providers/today_provider.dart';
import '../../subjects/providers/subjects_provider.dart';
import '../../calendar/providers/calendar_provider.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../holidays/providers/holidays_provider.dart';
import '../../../shared/providers/semesters_provider.dart';

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
  final Ref? _ref;
  final ApiClient _client = ApiClient();
  final LocalStorage _storage = LocalStorage();

  AuthNotifier([this._ref]) : super(AuthState(isAuthenticated: false, isLoading: true)) {
    checkInitialAuth();
  }

  void invalidateUserData() {
    final ref = _ref;
    if (ref != null) {
      ref.invalidate(profileProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(setupProvider);
      ref.invalidate(todayProvider);
      ref.invalidate(subjectsProvider);
      ref.invalidate(calendarProvider);
      ref.invalidate(analyticsProvider);
      ref.invalidate(holidaysProvider);
      ref.invalidate(semestersProvider);
    }
  }

  void setCustomError(String message) {
    state = state.copyWith(errorMessage: message, isLoading: false);
  }

  String _parseErrorDetail(dynamic detail, {String defaultMsg = 'An error occurred.'}) {
    if (detail == null) return defaultMsg;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        final msg = first['msg'].toString();
        if (msg.contains('valid email')) {
          return 'Please enter a valid email address.';
        }
        return msg;
      }
      return first.toString();
    }
    if (detail is Map) {
      return detail['msg']?.toString() ?? detail['message']?.toString() ?? detail.toString();
    }
    return detail.toString();
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
      invalidateUserData();
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
          msg = _parseErrorDetail(e.response!.data['detail'], defaultMsg: msg);
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
      invalidateUserData();
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
          msg = _parseErrorDetail(e.response!.data['detail'], defaultMsg: msg);
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

  Future<bool> signInWithGoogle({
    String? mockIdToken,
    String? mockAccessToken,
    String? mockEmail,
    String? mockName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      String? idToken = mockIdToken;
      String? accessToken = mockAccessToken;
      String? email = mockEmail;
      String? name = mockName;

      if (idToken == null && accessToken == null) {
        final String? clientId = AppConfig.googleServerClientId.isNotEmpty
            ? AppConfig.googleServerClientId
            : null;

        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? clientId : null,
          serverClientId: clientId,
          scopes: ['email', 'profile'],
        );
        final GoogleSignInAccount? account = await googleSignIn.signIn();
        if (account == null) {
          state = state.copyWith(isLoading: false);
          return false;
        }
        final GoogleSignInAuthentication auth = await account.authentication;
        idToken = auth.idToken;
        accessToken = auth.accessToken;
        email = account.email;
        name = account.displayName;
      }

      final payload = <String, dynamic>{
        if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
        if (accessToken != null && accessToken.isNotEmpty) 'access_token': accessToken,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (name != null && name.trim().isNotEmpty) 'full_name': name.trim(),
      };

      if (!payload.containsKey('id_token') && !payload.containsKey('access_token')) {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: 'Google authentication did not return credentials. Check your Google Cloud origins.',
        );
        return false;
      }

      final resp = await _client.dio.post(
        ApiEndpoints.googleAuth,
        data: payload,
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
      invalidateUserData();
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: user,
      );
      return true;
    } on PlatformException catch (pEx, st) {
      debugPrint('[Google Auth PlatformException] ${pEx.code}: ${pEx.message}\n$st');
      final msg = pEx.message ?? 'Google Sign-In is unavailable on this device platform (${pEx.code}).';
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    } catch (e, st) {
      debugPrint('[Google Auth Error] $e\n$st');
      String msg = 'Google authentication failed.';
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['detail'] != null) {
          msg = _parseErrorDetail(e.response!.data['detail'], defaultMsg: msg);
        } else if (e.response?.data is String && (e.response!.data as String).isNotEmpty) {
          msg = e.response!.data as String;
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          msg = "Couldn't connect to server. Check your connection.";
        } else if (e.message != null && e.message!.isNotEmpty) {
          msg = e.message!;
        }
      } else {
        final errStr = e.toString().replaceAll('Exception:', '').trim();
        msg = errStr.isNotEmpty ? 'Google Sign-In: $errStr' : 'Google authentication failed.';
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
    invalidateUserData();
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
