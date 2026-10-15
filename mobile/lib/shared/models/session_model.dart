class ClassSessionModel {
  final String id;
  final String semesterId;
  final String subjectId;
  final String subjectName;
  final String subjectColor;
  final String subjectIcon;
  final String date;
  final String? startTime;
  final String? endTime;
  final String? facultyName;
  final String? room;
  final String sessionStatus;
  final bool isExtra;
  final String? timetableEntryId;
  final String? subjectCode;
  final String? timeStatus; // "Done", "Now", "Upcoming", null
  String? attendanceStatus; // "ATTENDED", "ABSENT", "NOT_HELD", null
  final String? attendanceId;
  final String? classType;

  ClassSessionModel({
    required this.id,
    this.timetableEntryId,
    required this.semesterId,
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    required this.subjectColor,
    required this.subjectIcon,
    required this.date,
    this.startTime,
    this.endTime,
    this.facultyName,
    this.room,
    required this.sessionStatus,
    required this.isExtra,
    this.timeStatus,
    this.attendanceStatus,
    this.attendanceId,
    this.classType,
  });

  String get displayClassType {
    if (classType == null) return 'Others';
    final upper = classType!.trim().toUpperCase();
    if (upper == 'THEORY') return 'Theory';
    if (upper == 'LAB') return 'Lab';
    return 'Others';
  }

  factory ClassSessionModel.fromJson(Map<String, dynamic> json) {
    return ClassSessionModel(
      id: json['id']?.toString() ?? '',
      timetableEntryId: json['timetable_entry_id']?.toString(),
      semesterId: json['semester_id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? '',
      subjectName: json['subject_name'] ?? 'Class',
      subjectCode: json['subject_code'],
      subjectColor: json['subject_color'] ?? '#C96E5B',
      subjectIcon: json['subject_icon'] ?? 'book',
      date: json['date'] ?? '',
      startTime: json['start_time'],
      endTime: json['end_time'],
      facultyName: json['faculty_name'],
      room: json['room'],
      sessionStatus: json['session_status'] ?? 'SCHEDULED',
      isExtra: json['is_extra'] ?? false,
      timeStatus: json['time_status'],
      attendanceStatus: json['attendance_status'],
      attendanceId: json['attendance_id']?.toString(),
      classType: json['class_type']?.toString(),
    );
  }
}
