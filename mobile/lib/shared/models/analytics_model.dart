import 'subject_model.dart';

class InsightModel {
  final String type;
  final String severity;
  final String? subjectId;
  final String? subjectName;
  final String headline;
  final String message;
  final String? action;

  InsightModel({
    required this.type,
    required this.severity,
    this.subjectId,
    this.subjectName,
    required this.headline,
    required this.message,
    this.action,
  });

  factory InsightModel.fromJson(Map<String, dynamic> json) {
    return InsightModel(
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'info',
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      headline: json['headline'] ?? '',
      message: json['message'] ?? '',
      action: json['action'],
    );
  }
}

class TrendPointModel {
  final String label;
  final double? percentage;
  final int attended;
  final int conducted;

  TrendPointModel({
    required this.label,
    this.percentage,
    required this.attended,
    required this.conducted,
  });

  factory TrendPointModel.fromJson(Map<String, dynamic> json) {
    return TrendPointModel(
      label: json['label'] ?? '',
      percentage: (json['percentage'] as num?)?.toDouble(),
      attended: json['attended'] ?? 0,
      conducted: json['conducted'] ?? 0,
    );
  }
}

class AnalyticsOverviewModel {
  final String semesterId;
  final String semesterLabel;
  final int totalAttended;
  final int totalAbsent;
  final int totalConducted;
  final double? overallPercentage;
  final bool hasData;
  final String status;
  final String statusLabel;
  final double minimumRequirement;
  final double personalTarget;
  final int? classesNeededForMin;
  final int? classesNeededForTarget;
  final int maxSafeAbsences;
  final int totalRecoveryClassesNeeded;
  final int totalSafeAbsencesMargin;
  final List<SubjectModel> subjects;
  final List<InsightModel> insights;
  final List<TrendPointModel> trends;
  final double monthOverMonthChange;
  
  // Semester-wide forecast
  final int? totalRemainingClasses;
  final double? projectedOverallFinalPercentage;
  final String? forecastStatus;

  AnalyticsOverviewModel({
    required this.semesterId,
    required this.semesterLabel,
    required this.totalAttended,
    required this.totalAbsent,
    required this.totalConducted,
    this.overallPercentage,
    required this.hasData,
    required this.status,
    required this.statusLabel,
    required this.minimumRequirement,
    required this.personalTarget,
    this.classesNeededForMin,
    this.classesNeededForTarget,
    required this.maxSafeAbsences,
    required this.totalRecoveryClassesNeeded,
    required this.totalSafeAbsencesMargin,
    required this.subjects,
    required this.insights,
    required this.trends,
    required this.monthOverMonthChange,
    this.totalRemainingClasses,
    this.projectedOverallFinalPercentage,
    this.forecastStatus,
  });

  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    final subList = (json['subjects'] as List? ?? [])
        .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final insList = (json['insights'] as List? ?? [])
        .map((e) => InsightModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final trList = (json['trends'] as List? ?? [])
        .map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AnalyticsOverviewModel(
      semesterId: json['semester_id'] ?? '',
      semesterLabel: json['semester_label'] ?? '5th Semester',
      totalAttended: json['total_attended'] ?? 0,
      totalAbsent: json['total_absent'] ?? 0,
      totalConducted: json['total_conducted'] ?? 0,
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble(),
      hasData: json['has_data'] ?? false,
      status: json['status'] ?? 'NO_DATA',
      statusLabel: json['status_label'] ?? 'No attendance data yet',
      minimumRequirement: (json['minimum_requirement'] as num?)?.toDouble() ?? 75.0,
      personalTarget: (json['personal_target'] as num?)?.toDouble() ?? 75.0,
      classesNeededForMin: json['classes_needed_for_min'],
      classesNeededForTarget: json['classes_needed_for_target'],
      maxSafeAbsences: json['max_safe_absences'] ?? 0,
      totalRecoveryClassesNeeded: json['total_recovery_classes_needed'] ?? 0,
      totalSafeAbsencesMargin: json['total_safe_absences_margin'] ?? 0,
      subjects: subList,
      insights: insList,
      trends: trList,
      monthOverMonthChange: (json['month_over_month_change'] as num?)?.toDouble() ?? 0.0,
      totalRemainingClasses: json['total_remaining_classes'],
      projectedOverallFinalPercentage: (json['projected_overall_final_percentage'] as num?)?.toDouble(),
      forecastStatus: json['forecast_status'],
    );
  }
}
