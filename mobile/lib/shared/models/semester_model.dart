class SemesterModel {
  final String id;
  final String userId;
  final int semesterNumber;
  final String label;
  final String startDate;
  final String endDate;
  final String status;
  final bool isActive;
  final int totalWeeks;
  final int currentWeek;
  final int weeksRemaining;
  final double progressPercentage;

  SemesterModel({
    required this.id,
    required this.userId,
    required this.semesterNumber,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.isActive,
    required this.totalWeeks,
    required this.currentWeek,
    required this.weeksRemaining,
    required this.progressPercentage,
  });

  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      semesterNumber: json['semester_number'] ?? 5,
      label: json['label'] ?? '5th Semester',
      startDate: json['start_date'] ?? '2026-08-01',
      endDate: json['end_date'] ?? '2026-12-20',
      status: json['status'] ?? 'ACTIVE',
      isActive: json['is_active'] ?? false,
      totalWeeks: json['total_weeks'] ?? 16,
      currentWeek: json['current_week'] ?? 12,
      weeksRemaining: json['weeks_remaining'] ?? 4,
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 75.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'semester_number': semesterNumber,
    'label': label,
    'start_date': startDate,
    'end_date': endDate,
    'status': status,
    'is_active': isActive,
    'total_weeks': totalWeeks,
    'current_week': currentWeek,
    'weeks_remaining': weeksRemaining,
    'progress_percentage': progressPercentage,
  };
}
