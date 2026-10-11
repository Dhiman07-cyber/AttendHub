class SubjectModel {
  final String id;
  final String semesterId;
  final String name;
  final String? code;
  final String? facultyName;
  final String color;
  final String icon;
  final bool isActive;
  final int attended;
  final int conducted;
  final int? absent;
  final double? percentage;
  final String status;
  final String statusLabel;
  final String? scheduleSummary;
  final int? classesNeededForMin;
  final int? classesNeededForTarget;
  final int maxSafeAbsences;
  final String? canMissMessage;
  final String? recoveryMessage;

  SubjectModel({
    required this.id,
    required this.semesterId,
    required this.name,
    this.code,
    this.facultyName,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.attended,
    required this.conducted,
    this.absent,
    this.percentage,
    required this.status,
    required this.statusLabel,
    this.scheduleSummary,
    this.classesNeededForMin,
    this.classesNeededForTarget,
    this.maxSafeAbsences = 0,
    this.canMissMessage,
    this.recoveryMessage,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? '',
      semesterId: json['semester_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      facultyName: json['faculty_name'],
      color: json['color'] ?? '#C96E5B',
      icon: json['icon'] ?? 'book',
      isActive: json['is_active'] ?? true,
      attended: json['attended'] ?? 0,
      conducted: json['conducted'] ?? 0,
      absent: json['absent'],
      percentage: (json['percentage'] as num?)?.toDouble(),
      status: json['status'] ?? 'NO_DATA',
      statusLabel: json['status_label'] ?? 'No attendance data yet',
      scheduleSummary: json['schedule_summary'],
      classesNeededForMin: json['classes_needed_for_min'],
      classesNeededForTarget: json['classes_needed_for_target'],
      maxSafeAbsences: json['max_safe_absences'] ?? 0,
      canMissMessage: json['can_miss_message'],
      recoveryMessage: json['recovery_message'],
    );
  }

  SubjectModel copyWith({
    String? id,
    String? semesterId,
    String? name,
    String? code,
    String? facultyName,
    String? color,
    String? icon,
    bool? isActive,
    int? attended,
    int? conducted,
    int? absent,
    double? percentage,
    String? status,
    String? statusLabel,
    String? scheduleSummary,
    int? classesNeededForMin,
    int? classesNeededForTarget,
    int? maxSafeAbsences,
    String? canMissMessage,
    String? recoveryMessage,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      semesterId: semesterId ?? this.semesterId,
      name: name ?? this.name,
      code: code ?? this.code,
      facultyName: facultyName ?? this.facultyName,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      attended: attended ?? this.attended,
      conducted: conducted ?? this.conducted,
      absent: absent ?? this.absent,
      percentage: percentage ?? this.percentage,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      scheduleSummary: scheduleSummary ?? this.scheduleSummary,
      classesNeededForMin: classesNeededForMin ?? this.classesNeededForMin,
      classesNeededForTarget: classesNeededForTarget ?? this.classesNeededForTarget,
      maxSafeAbsences: maxSafeAbsences ?? this.maxSafeAbsences,
      canMissMessage: canMissMessage ?? this.canMissMessage,
      recoveryMessage: recoveryMessage ?? this.recoveryMessage,
    );
  }
}
