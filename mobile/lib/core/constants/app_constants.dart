class AppConstants {
  static const String appName = 'AttendHub';
  static const String tagline = 'Track · Plan · Stay Above';
  
  static const double defaultMinimumAttendance = 75.0;
  static const double defaultPersonalTarget = 75.0;
  static const double defaultLowAttendanceAlert = 70.0;
  
  // Storage keys
  static const String keyAccessToken = 'attendhub_access_token';
  static const String keyRefreshToken = 'attendhub_refresh_token';
  static const String keyUserId = 'attendhub_user_id';
  static const String keyUserEmail = 'attendhub_user_email';
  static const String keyUserName = 'attendhub_user_name';
  static const String keyUserAvatar = 'attendhub_user_avatar';
  static const String keyHasOnboarded = 'attendhub_has_onboarded';
  static const String keyActiveTab = 'attendhub_active_tab_index';
  static const String keySecondaryRoute = 'attendhub_secondary_route';
}
