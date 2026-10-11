class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String avatarInitial;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarInitial,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'Student',
      avatarInitial: json['avatar_initial'] ?? 'S',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_initial': avatarInitial,
    'is_active': isActive,
  };
}

class AcademicProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String universityName;
  final String courseName;
  final String? studentIdNumber;
  final int academicDurationYears;
  final int? academicSessionStart;
  final int? academicSessionEnd;
  final String? currentSemesterId;
  final String? currentSemesterLabel;
  final double minimumAttendance;
  final double personalTarget;
  final double lowAttendanceAlert;

  AcademicProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.universityName,
    required this.courseName,
    this.studentIdNumber,
    required this.academicDurationYears,
    this.academicSessionStart,
    this.academicSessionEnd,
    this.currentSemesterId,
    this.currentSemesterLabel,
    required this.minimumAttendance,
    required this.personalTarget,
    required this.lowAttendanceAlert,
  });

  factory AcademicProfileModel.fromJson(Map<String, dynamic> json) {
    return AcademicProfileModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? 'Dhiman Saikia',
      email: json['email'] ?? '',
      universityName: json['university_name'] ?? 'Assam down town University',
      courseName: json['course_name'] ?? 'B.Tech Computer Science & Engineering',
      studentIdNumber: json['student_id_number'] ?? 'ADTU/0/2024-28/BCSM/001',
      academicDurationYears: json['academic_duration_years'] ?? 4,
      academicSessionStart: json['academic_session_start'] ?? 2024,
      academicSessionEnd: json['academic_session_end'] ?? 2028,
      currentSemesterId: json['current_semester_id'],
      currentSemesterLabel: json['current_semester_label'] ?? '5th Semester',
      minimumAttendance: (json['minimum_attendance'] as num?)?.toDouble() ?? 75.0,
      personalTarget: (json['personal_target'] as num?)?.toDouble() ?? 75.0,
      lowAttendanceAlert: (json['low_attendance_alert'] as num?)?.toDouble() ?? 70.0,
    );
  }
}
