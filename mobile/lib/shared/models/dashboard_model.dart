import 'session_model.dart';
import 'holiday_model.dart';
import 'analytics_model.dart';

class DashboardSubjectAttentionModel {
  final String subjectId;
  final String name;
  final double? percentage;
  final String color;
  final String icon;
  final String status;
  final String neededClassesMessage;

  DashboardSubjectAttentionModel({
    required this.subjectId,
    required this.name,
    this.percentage,
    required this.color,
    required this.icon,
    required this.status,
    required this.neededClassesMessage,
  });

  factory DashboardSubjectAttentionModel.fromJson(Map<String, dynamic> json) {
    return DashboardSubjectAttentionModel(
      subjectId: json['subject_id'] ?? '',
      name: json['name'] ?? '',
      percentage: (json['percentage'] as num?)?.toDouble(),
      color: json['color'] ?? '#C96E5B',
      icon: json['icon'] ?? 'book',
      status: json['status'] ?? 'CRITICAL',
      neededClassesMessage: json['needed_classes_message'] ?? '',
    );
  }
}

class DashboardOverviewModel {
  final String userName;
  final String currentSemesterLabel;
  final String courseName;
  final String? enrollmentId;
  final double? overallPercentage;
  final int totalAttended;
  final int totalConducted;
  final double targetPercentage;
  final double minimumPercentage;
  final double trendFromLastMonth;
  final int currentWeek;
  final int totalWeeks;
  final int weeksRemaining;
  final double semesterProgressPct;
  final String todayDateStr;
  final List<ClassSessionModel> todaySessions;
  final List<DashboardSubjectAttentionModel> subjectsNeedingAttention;
  final HolidayModel? upcomingHoliday;
  final InsightModel? quickInsight;
  final List<TrendPointModel> trendPoints;

  DashboardOverviewModel({
    required this.userName,
    required this.currentSemesterLabel,
    required this.courseName,
    this.enrollmentId,
    this.overallPercentage,
    required this.totalAttended,
    required this.totalConducted,
    required this.targetPercentage,
    required this.minimumPercentage,
    required this.trendFromLastMonth,
    required this.currentWeek,
    required this.totalWeeks,
    required this.weeksRemaining,
    required this.semesterProgressPct,
    required this.todayDateStr,
    required this.todaySessions,
    required this.subjectsNeedingAttention,
    this.upcomingHoliday,
    this.quickInsight,
    required this.trendPoints,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final sessList = (json['today_sessions'] as List? ?? [])
        .map((e) => ClassSessionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final attList = (json['subjects_needing_attention'] as List? ?? [])
        .map((e) => DashboardSubjectAttentionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final trList = (json['trend_points'] as List? ?? [])
        .map((e) => TrendPointModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return DashboardOverviewModel(
      userName: json['user_name'] ?? 'Student',
      currentSemesterLabel: json['current_semester_label'] ?? '5th Semester',
      courseName: json['course_name'] ?? 'Academic',
      enrollmentId: json['enrollment_id'],

      overallPercentage: (json['overall_percentage'] as num?)?.toDouble(),
      totalAttended: json['total_attended'] ?? 0,
      totalConducted: json['total_conducted'] ?? 0,
      targetPercentage: (json['target_percentage'] as num?)?.toDouble() ?? 75.0,
      minimumPercentage: (json['minimum_percentage'] as num?)?.toDouble() ?? 75.0,
      trendFromLastMonth: (json['trend_from_last_month'] as num?)?.toDouble() ?? 0.0,
      currentWeek: json['current_week'] ?? 12,
      totalWeeks: json['total_weeks'] ?? 16,
      weeksRemaining: json['weeks_remaining'] ?? 4,
      semesterProgressPct: (json['semester_progress_pct'] as num?)?.toDouble() ?? 75.0,
      todayDateStr: json['today_date_str'] ?? 'Wed, 8 Oct 2026',
      todaySessions: sessList,
      subjectsNeedingAttention: attList,
      upcomingHoliday: json['upcoming_holiday'] != null
          ? HolidayModel.fromJson(Map<String, dynamic>.from(json['upcoming_holiday'] as Map))
          : null,
      quickInsight: json['quick_insight'] != null
          ? InsightModel.fromJson(Map<String, dynamic>.from(json['quick_insight'] as Map))
          : null,
      trendPoints: trList,
    );
  }
}