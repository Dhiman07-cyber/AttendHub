import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      await _secureStorage.write(key: AppConstants.keyAccessToken, value: accessToken);
      await _secureStorage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, accessToken);
    await prefs.setString(AppConstants.keyRefreshToken, refreshToken);
  }

  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.keyRefreshToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyRefreshToken);
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserEmail, user.email);
    await prefs.setString(AppConstants.keyUserName, user.fullName);
    await prefs.setString(AppConstants.keyUserAvatar, user.avatarInitial);
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.keyUserId);
    final email = prefs.getString(AppConstants.keyUserEmail);
    final fullName = prefs.getString(AppConstants.keyUserName);
    final avatar = prefs.getString(AppConstants.keyUserAvatar);
    if (id != null && email != null) {
      return UserModel(
        id: id,
        email: email,
        fullName: fullName ?? 'Student',
        avatarInitial: avatar ?? (fullName != null && fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S'),
        isActive: true,
      );
    }
    return null;
  }

  Future<void> clearAuth() async {
    try {
      await _secureStorage.delete(key: AppConstants.keyAccessToken);
      await _secureStorage.delete(key: AppConstants.keyRefreshToken);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAccessToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserAvatar);
    await clearNavState();
  }

  Future<void> saveNavState({int? tabIndex, String? secondaryRoute}) async {
    final prefs = await SharedPreferences.getInstance();
    if (tabIndex != null) {
      await prefs.setInt(AppConstants.keyActiveTab, tabIndex);
    }
    if (secondaryRoute != null && secondaryRoute.isNotEmpty) {
      await prefs.setString(AppConstants.keySecondaryRoute, secondaryRoute);
    } else {
      await prefs.remove(AppConstants.keySecondaryRoute);
    }
  }

  Future<({int tabIndex, String? secondaryRoute})> getNavState() async {
    final prefs = await SharedPreferences.getInstance();
    final tab = prefs.getInt(AppConstants.keyActiveTab) ?? 0;
    final sec = prefs.getString(AppConstants.keySecondaryRoute);
    return (tabIndex: tab, secondaryRoute: sec);
  }

  Future<void> clearNavState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyActiveTab);
    await prefs.remove(AppConstants.keySecondaryRoute);
  }

  Future<bool> hasOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyHasOnboarded) ?? false;
  }

  Future<void> setOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyHasOnboarded, value);
  }

  Future<void> saveAcademicSetupDraft(String userId, Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(draft);
    if (userId.isNotEmpty) {
      await prefs.setString('academic_setup_draft_$userId', jsonStr);
    }
    // Always persist to latest and default fallback keys to eliminate any ID mismatch loss
    await prefs.setString('academic_setup_draft_latest', jsonStr);
    await prefs.setString('academic_setup_draft_default', jsonStr);
  }

  Future<Map<String, dynamic>?> getAcademicSetupDraft(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try userId specific key if valid
    if (userId.isNotEmpty && userId != 'default') {
      final str = prefs.getString('academic_setup_draft_$userId');
      if (str != null && str.isNotEmpty) {
        final parsed = _tryParseDraft(str);
        if (parsed != null) return parsed;
      }
    }

    // 2. Try latest fallback key
    final latestStr = prefs.getString('academic_setup_draft_latest');
    if (latestStr != null && latestStr.isNotEmpty) {
      final parsed = _tryParseDraft(latestStr);
      if (parsed != null) return parsed;
    }

    // 3. Try default fallback key
    final defaultStr = prefs.getString('academic_setup_draft_default');
    if (defaultStr != null && defaultStr.isNotEmpty) {
      final parsed = _tryParseDraft(defaultStr);
      if (parsed != null) return parsed;
    }

    return null;
  }

  Map<String, dynamic>? _tryParseDraft(String str) {
    try {
      final decoded = jsonDecode(str);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> clearAcademicSetupDraft(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId.isNotEmpty) {
      await prefs.remove('academic_setup_draft_$userId');
    }
    await prefs.remove('academic_setup_draft_latest');
    await prefs.remove('academic_setup_draft_default');
  }

  // Attendance Draft Storage (Scoped by user_id, semester_id, date)
  String _attendanceDraftKey(String userId, String semesterId, String date) =>
      'attendance_draft_${userId}_${semesterId}_$date';

  Future<void> saveAttendanceDraft({
    required String userId,
    required String semesterId,
    required String date,
    required Map<String, String> marks,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _attendanceDraftKey(userId, semesterId, date);
    if (marks.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(marks));
    }
  }

  Future<Map<String, String>?> getAttendanceDraft({
    required String userId,
    required String semesterId,
    required String date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _attendanceDraftKey(userId, semesterId, date);
    final str = prefs.getString(key);
    if (str != null && str.isNotEmpty) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearAttendanceDraft({
    required String userId,
    required String semesterId,
    required String date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _attendanceDraftKey(userId, semesterId, date);
    await prefs.remove(key);
  }

  static const String _keyCachedSemesters = 'attendhub_cached_semesters_list';

  Future<void> saveCachedSemesters(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedSemesters, jsonStr);
  }

  Future<String?> getCachedSemesters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedSemesters);
  }
}

