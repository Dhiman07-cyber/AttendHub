class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Profile
  static const String profile = '/profile';
  static const String setupStatus = '/profile/setup-status';
  static const String setup = '/profile/setup';
  static const String setupData = '/profile/setup-data';


  // Semesters
  static const String semesters = '/semesters';
  static const String switchSemester = '/semesters/switch';

  // Subjects
  static const String subjects = '/subjects';

  // Timetable
  static const String timetable = '/timetable';
  static const String timetableWeeklyStatus = '/timetable/weekly-status';

  // Sessions
  static const String sessions = '/sessions';
  static const String extraClass = '/sessions/extra';

  // Attendance
  static const String todayAttendance = '/attendance/today';
  static const String dayAttendance = '/attendance/day';
  static const String bulkAttendance = '/attendance/bulk';
  static const String bulkDayAttendance = '/attendance/day/bulk';
  static const String correctAttendance = '/attendance';

  // Holidays
  static const String holidays = '/holidays';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Calendar
  static const String calendar = '/calendar';

  // Analytics
  static const String analytics = '/analytics/overview';

  // Imports
  static const String importRoutineParse = '/imports/routine/parse';
  static const String importRoutineConfirm = '/imports/routine/confirm';
  static const String importHolidaysParse = '/imports/holidays/parse';
  static const String importHolidaysConfirm = '/imports/holidays/confirm';
}
