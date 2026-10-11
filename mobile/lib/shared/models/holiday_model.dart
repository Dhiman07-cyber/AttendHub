class HolidayModel {
  final String id;
  final String userId;
  final String? semesterId;
  final String title;
  final String startDate;
  final String endDate;
  final String category;
  final String? notes;
  final String source;
  final int durationDays;
  final bool isUpcoming;
  final String relativeTimeLabel;

  HolidayModel({
    required this.id,
    required this.userId,
    this.semesterId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.category,
    this.notes,
    required this.source,
    required this.durationDays,
    required this.isUpcoming,
    required this.relativeTimeLabel,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      semesterId: json['semester_id'],
      title: json['title'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      category: json['category'] ?? 'University Holiday',
      notes: json['notes'],
      source: json['source'] ?? 'manual',
      durationDays: json['duration_days'] ?? 1,
      isUpcoming: json['is_upcoming'] ?? true,
      relativeTimeLabel: json['relative_time_label'] ?? '',
    );
  }
}
