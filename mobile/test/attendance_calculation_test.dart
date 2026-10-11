import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendhub/shared/models/subject_model.dart';
import 'package:attendhub/shared/models/session_model.dart';

void main() {
  group('AttendHub Attendance Calculations & Model Tests', () {
    test('SubjectModel JSON parsing and metrics calculation', () {
      final json = {
        'id': 'sub-1',
        'semester_id': 'sem-5',
        'name': 'Software Engineering',
        'code': 'CS-501',
        'faculty_name': 'Prof. A. Sharma',
        'color': '#E06D53',
        'icon': 'code',
        'is_active': true,
        'attended': 33,
        'conducted': 40,
        'absent': 7,
        'percentage': 82.5,
        'status': 'ON_TARGET',
        'status_label': 'On Target',
        'max_safe_absences': 4,
        'classes_needed_for_min': 0,
        'can_miss_message':
            'You can miss up to 4 classes and still stay above 75%.',
      };

      final sub = SubjectModel.fromJson(json);
      expect(sub.name, 'Software Engineering');
      expect(sub.percentage, 82.5);
      expect(sub.maxSafeAbsences, 4);
      expect(sub.classesNeededForMin, 0);
      expect(sub.attended + (sub.absent ?? 0), sub.conducted);
    });

    test('ClassSessionModel state toggles', () {
      final session = ClassSessionModel(
        id: 's-1',
        semesterId: 'sem-5',
        subjectId: 'sub-1',
        subjectName: 'Software Engineering',
        subjectColor: '#E06D53',
        subjectIcon: 'code',
        date: '2026-10-08',
        startTime: '09:00',
        endTime: '10:00',
        facultyName: 'Prof. A. Sharma',
        room: 'Room 101',
        sessionStatus: 'SCHEDULED',
        isExtra: false,
        timeStatus: 'Done',
        attendanceStatus: 'ATTENDED',
      );

      expect(session.timeStatus, 'Done');
      expect(session.attendanceStatus, 'ATTENDED');
    });

    test('Formula verification: Safe absence boundary', () {
      // 33 attended, 40 conducted, min requirement = 75%
      // 33 / (40 + x) >= 0.75 => x <= (33 - 30) / 0.75 = 4
      const attended = 33;
      const conducted = 40;
      const rMin = 0.75;
      final maxAbsences = ((attended - (rMin * conducted)) / rMin).floor();
      expect(maxAbsences, 4);
    });

    test('Formula verification: Recovery needed', () {
      // 15 attended, 22 conducted, min requirement = 75%
      // (15 + x) / (22 + x) >= 0.75 => x >= (0.75 * 22 - 15) / (1 - 0.75) = (16.5 - 15) / 0.25 = 6
      const attended = 15;
      const conducted = 22;
      const rMin = 0.75;
      final needed = ((rMin * conducted - attended) / (1.0 - rMin)).ceil();
      expect(needed, 6);
    });

    test('Edge case: Zero conducted classes produces null percentage', () {
      const attended = 0;
      const conducted = 0;
      const double? pct = conducted > 0 ? (attended / conducted) * 100.0 : null;
      expect(pct, isNull);
    });

    test(
        'Edge case: Exactly 75% requires 0 recovery and allows 0 safe absences',
        () {
      const attended = 15;
      const conducted = 20;
      const rMin = 0.75;
      const pct = (attended / conducted) * 100.0;
      expect(pct, 75.0);

      final needed =
          max(0, ((rMin * conducted - attended) / (1.0 - rMin)).ceil());
      expect(needed, 0);

      final safe = max(0, ((attended - (rMin * conducted)) / rMin).floor());
      expect(safe, 0);
    });

    test('Edge case: Below 75% must strictly have 0 safe absences', () {
      const attended = 14;
      const conducted = 20; // 70%
      const rMin = 0.75;
      const pct = (attended / conducted) * 100.0;
      expect(pct, 70.0);

      // Safe absences rule: if current < rMin, safe absences MUST be 0
      final safe = pct < (rMin * 100.0)
          ? 0
          : max(0, ((attended - (rMin * conducted)) / rMin).floor());
      expect(safe, 0);

      final needed =
          max(0, ((rMin * conducted - attended) / (1.0 - rMin)).ceil());
      // (15 - 14) / 0.25 = 4 needed: (14+4)/(20+4) = 18/24 = 75.0%
      expect(needed, 4);
    });

    test('Edge case: 100% attendance allows safe absences', () {
      const attended = 20;
      const conducted = 20;
      const rMin = 0.75;
      final safe = max(0, ((attended - (rMin * conducted)) / rMin).floor());
      // (20 - 15) / 0.75 = 5 / 0.75 = 6.66 => 6 safe absences
      // (20 / 26) = 76.9% >= 75%
      expect(safe, 6);
    });

    test('Aggregate attendance vs averaging subject percentages', () {
      // Sub A: 90/100 = 90%
      // Sub B: 1/2 = 50%
      // Average of percentages = 70% (INCORRECT)
      // Raw aggregate = 91/102 = 89.2% (CORRECT)
      const subAAttended = 90;
      const subAConducted = 100;
      const subBAttended = 1;
      const subBConducted = 2;

      const totalAttended = subAAttended + subBAttended;
      const totalConducted = subAConducted + subBConducted;
      final aggregatePct =
          ((totalAttended / totalConducted) * 100.0).roundToDouble();

      final averagePct = (((subAAttended / subAConducted * 100.0) +
                  (subBAttended / subBConducted * 100.0)) /
              2.0)
          .roundToDouble();

      expect(aggregatePct, 89.0);
      expect(averagePct, 70.0);
      expect(aggregatePct != averagePct, isTrue);
    });

    test('NOT_HELD, CANCELLED, and HOLIDAY must never count in conducted total',
        () {
      int attended = 0;
      int absent = 0;

      final sessionList = [
        'ATTENDED',
        'ATTENDED',
        'ABSENT',
        'NOT_HELD',
        'CANCELLED',
        'HOLIDAY'
      ];

      for (final s in sessionList) {
        if (s == 'ATTENDED') attended++;
        if (s == 'ABSENT') absent++;
      }

      final conducted = attended + absent;
      expect(conducted, 3);
      expect(attended, 2);
      expect(absent, 1);
    });
  });
}
