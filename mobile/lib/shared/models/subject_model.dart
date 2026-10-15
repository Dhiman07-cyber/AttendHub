/// Theory or Lab breakdown metrics for a subject
class TypeBreakdownMetrics {
  final int attended;
  final int absent;
  final int conducted;
  final double? percentage;
  final bool hasData;
  final String status;
  final String statusLabel;
  final int? classesNeededForMin;
  final int? classesNeededForTarget;
  final int maxSafeAbsences;
  final String? canMissMessage;
  final String? recoveryMessage;

  TypeBreakdownMetrics({
    required this.attended,
    required this.absent,
    required this.conducted,
    this.percentage,
    required this.hasData,
    required this.status,
    required this.statusLabel,
    this.classesNeededForMin,
    this.classesNeededForTarget,
    required this.maxSafeAbsences,
    this.canMissMessage,
    this.recoveryMessage,
  });

  factory TypeBreakdownMetrics.fromJson(Map<String, dynamic> json) {
    return TypeBreakdownMetrics(
      attended: json['attended'] ?? 0,
      absent: json['absent'] ?? 0,
      conducted: json['conducted'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble(),
      hasData: json['has_data'] ?? false,
      status: json['status'] ?? 'NO_DATA',
      statusLabel: json['status_label'] ?? 'No data yet',
      classesNeededForMin: json['classes_needed_for_min'],
      classesNeededForTarget: json['classes_needed_for_target'],
      maxSafeAbsences: json['max_safe_absences'] ?? 0,
      canMissMessage: json['can_miss_message'],
      recoveryMessage: json['recovery_message'],
    );
  }
}

class SubjectModel {
  final String id;
  final String semesterId;
  final String name;
  final String? code;
  final String? facultyName;
  final String color;
  final String icon;
  final bool isActive;
  // Overall metrics (Theory + Lab + Unclassified)
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
  
  // Theory/Lab breakdown
  final TypeBreakdownMetrics? theoryMetrics;
  final TypeBreakdownMetrics? labMetrics;
  final int unclassifiedAttended;
  final int unclassifiedConducted;
  
  // Forecast fields (future classes until semester end)
  final int? remainingClasses;
  final int? remainingTheoryClasses;
  final int? remainingLabClasses;
  final double? projectedFinalPercentage;
  final int? maxFutureAbsencesForMin;
  final int? maxFutureAbsencesForTarget;
  final String? forecastStatus;

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
    this.theoryMetrics,
    this.labMetrics,
    this.unclassifiedAttended = 0,
    this.unclassifiedConducted = 0,
    this.remainingClasses,
    this.remainingTheoryClasses,
    this.remainingLabClasses,
    this.projectedFinalPercentage,
    this.maxFutureAbsencesForMin,
    this.maxFutureAbsencesForTarget,
    this.forecastStatus,
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
      theoryMetrics: json['theory_metrics'] != null
          ? TypeBreakdownMetrics.fromJson(json['theory_metrics'] as Map<String, dynamic>)
          : null,
      labMetrics: json['lab_metrics'] != null
          ? TypeBreakdownMetrics.fromJson(json['lab_metrics'] as Map<String, dynamic>)
          : null,
      unclassifiedAttended: json['unclassified_attended'] ?? 0,
      unclassifiedConducted: json['unclassified_conducted'] ?? 0,
      remainingClasses: json['remaining_classes'],
      remainingTheoryClasses: json['remaining_theory_classes'],
      remainingLabClasses: json['remaining_lab_classes'],
      projectedFinalPercentage: (json['projected_final_percentage'] as num?)?.toDouble(),
      maxFutureAbsencesForMin: json['max_future_absences_for_min'],
      maxFutureAbsencesForTarget: json['max_future_absences_for_target'],
      forecastStatus: json['forecast_status'],
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
    TypeBreakdownMetrics? theoryMetrics,
    TypeBreakdownMetrics? labMetrics,
    int? unclassifiedAttended,
    int? unclassifiedConducted,
    int? remainingClasses,
    int? remainingTheoryClasses,
    int? remainingLabClasses,
    double? projectedFinalPercentage,
    int? maxFutureAbsencesForMin,
    int? maxFutureAbsencesForTarget,
    String? forecastStatus,
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
      theoryMetrics: theoryMetrics ?? this.theoryMetrics,
      labMetrics: labMetrics ?? this.labMetrics,
      unclassifiedAttended: unclassifiedAttended ?? this.unclassifiedAttended,
      unclassifiedConducted: unclassifiedConducted ?? this.unclassifiedConducted,
      remainingClasses: remainingClasses ?? this.remainingClasses,
      remainingTheoryClasses: remainingTheoryClasses ?? this.remainingTheoryClasses,
      remainingLabClasses: remainingLabClasses ?? this.remainingLabClasses,
      projectedFinalPercentage: projectedFinalPercentage ?? this.projectedFinalPercentage,
      maxFutureAbsencesForMin: maxFutureAbsencesForMin ?? this.maxFutureAbsencesForMin,
      maxFutureAbsencesForTarget: maxFutureAbsencesForTarget ?? this.maxFutureAbsencesForTarget,
      forecastStatus: forecastStatus ?? this.forecastStatus,
    );
  }
}
