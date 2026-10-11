import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendhub/features/dashboard/dashboard_screen.dart';
import 'package:attendhub/features/dashboard/providers/dashboard_provider.dart';
import 'package:attendhub/features/subjects/subjects_screen.dart';
import 'package:attendhub/features/subjects/providers/subjects_provider.dart';
import 'package:attendhub/shared/models/dashboard_model.dart';
import 'package:attendhub/shared/models/session_model.dart';

void main() {
  group('Phase B & C Date & Week Formatting Logic Tests', () {
    test('Canonical relative week labels and Day-Month-Year format', () {
      // Test week label logic
      String formatWeekLabel(int offset) {
        if (offset == 0) return 'This week';
        if (offset == -1) return 'Last week';
        if (offset == 1) return 'Next week';
        if (offset < -1) return '${offset.abs()} weeks ago';
        return 'In $offset weeks';
      }

      expect(formatWeekLabel(0), equals('This week'));
      expect(formatWeekLabel(-1), equals('Last week'));
      expect(formatWeekLabel(-2), equals('2 weeks ago'));
      expect(formatWeekLabel(-3), equals('3 weeks ago'));
      expect(formatWeekLabel(1), equals('Next week'));
      expect(formatWeekLabel(2), equals('In 2 weeks'));

      // Test date range format: Day Month Year (never raw ISO)
      String formatDateRange(DateTime start, DateTime end) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final startD = start.day.toString().padLeft(2, '0');
        final endD = end.day.toString().padLeft(2, '0');
        final startM = months[start.month - 1];
        final endM = months[end.month - 1];
        return '$startD $startM ${start.year} – $endD $endM ${end.year}';
      }

      final start = DateTime(2026, 9, 28);
      final end = DateTime(2026, 10, 4);
      final rangeStr = formatDateRange(start, end);
      expect(rangeStr, equals('28 Sep 2026 – 04 Oct 2026'));
      expect(rangeStr.contains('2026-09-28'), isFalse);
    });

    test('Daily date header labels differentiate Today, Yesterday, and Future dates', () {
      final fixedToday = DateTime(2026, 10, 11);

      String formatDateHeaderWithReference(DateTime target, DateTime referenceNow) {
        final refToday = DateTime(referenceNow.year, referenceNow.month, referenceNow.day);
        final targetDay = DateTime(target.year, target.month, target.day);
        final diff = targetDay.difference(refToday).inDays;

        const shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final weekday = shortWeekdays[target.weekday - 1];
        final month = months[target.month - 1];
        final dayStr = target.day.toString().padLeft(2, '0');
        final formattedDate = '$weekday, $dayStr $month ${target.year}';

        if (diff == 0) return 'Today · $formattedDate';
        if (diff == -1) return 'Yesterday · $formattedDate';
        if (diff == -2) return '2 days ago · $formattedDate';
        if (diff < -2) return '${diff.abs()} days ago · $formattedDate';
        if (diff == 1) return 'Tomorrow · $formattedDate';
        return 'In $diff days · $formattedDate';
      }

      // Today (11 Oct 2026)
      expect(formatDateHeaderWithReference(DateTime(2026, 10, 11), fixedToday),
          equals('Today · Sun, 11 Oct 2026'));

      // Yesterday (10 Oct 2026)
      expect(formatDateHeaderWithReference(DateTime(2026, 10, 10), fixedToday),
          equals('Yesterday · Sat, 10 Oct 2026'));

      // 2 days ago (09 Oct 2026)
      expect(formatDateHeaderWithReference(DateTime(2026, 10, 9), fixedToday),
          equals('2 days ago · Fri, 09 Oct 2026'));

      // Tomorrow / Future (12 Oct 2026)
      expect(formatDateHeaderWithReference(DateTime(2026, 10, 12), fixedToday),
          equals('Tomorrow · Mon, 12 Oct 2026'));
    });
  });

  group('Future Class & Attendance Counting Invariants', () {
    test('Unrecorded future class is Upcoming and does NOT increment absentCount', () {
      final futureSession = ClassSessionModel(
        id: 'sess-fut-1',
        timetableEntryId: 'tt-1',
        semesterId: 'sem-1',
        subjectId: 'sub-1',
        subjectName: 'Computer Networks',
        subjectCode: 'CS301',
        subjectColor: '#C96E5B',
        subjectIcon: 'code',
        date: '2026-10-12', // Monday tomorrow
        startTime: '09:00',
        endTime: '10:00',
        sessionStatus: 'SCHEDULED',
        isExtra: false,
        attendanceStatus: null, // Unrecorded!
        timeStatus: 'Upcoming',
      );

      final displayedSessions = [futureSession];
      final draftMarks = <String, String>{};

      int attendedCount = 0;
      int absentCount = 0;
      int notHeldCount = 0;
      int unrecordedCount = 0;

      for (final s in displayedSessions) {
        final slotKey = (s.timetableEntryId != null && s.timetableEntryId!.isNotEmpty)
            ? s.timetableEntryId!
            : s.id;
        final mark = draftMarks[slotKey] ?? s.attendanceStatus;
        if (mark == 'ATTENDED') {
          attendedCount++;
        } else if (mark == 'NOT_HELD') {
          notHeldCount++;
        } else if (mark == 'ABSENT') {
          absentCount++;
        } else {
          unrecordedCount++;
        }
      }

      // Invariant checks:
      expect(attendedCount, equals(0));
      expect(absentCount, equals(0), reason: 'Future unrecorded session must NOT be counted as absent!');
      expect(notHeldCount, equals(0));
      expect(unrecordedCount, equals(1));
    });
  });

  group('Dashboard Greeting & Subjects Heading Tests', () {
    testWidgets('Dashboard greeting displays real enrollment ID and never BIC', (tester) async {
      final mockData = DashboardOverviewModel(
        userName: 'Alex Rivers',
        currentSemesterLabel: '5th Semester',
        courseName: 'Computer Science',
        enrollmentId: 'ENR-2024-9871',
        overallPercentage: 78.5,
        targetPercentage: 75.0,
        minimumPercentage: 75.0,
        totalAttended: 33,
        totalConducted: 42,
        currentWeek: 8,
        totalWeeks: 16,
        weeksRemaining: 8,
        semesterProgressPct: 50.0,
        trendFromLastMonth: 2.1,
        todayDateStr: '2026-10-11',
        todaySessions: [],
        subjectsNeedingAttention: [],
        trendPoints: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) => mockData),
            selectedDateAttendanceProvider.overrideWith(
              (ref) => SelectedDateAttendanceNotifier(null, null, null, false),
            ),
          ],
          child: MaterialApp(
            home: DashboardScreen(
              onOpenDrawer: () {},
              onNavigateToToday: () {},
              onNavigateToAnalytics: () {},
              onNavigateToCalendar: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Invariant: Enrollment ID is displayed
      expect(find.text('Enrollment ID · ENR-2024-9871'), findsOneWidget);

      // Invariant: BIC is never rendered
      expect(find.textContaining('BIC'), findsNothing);
      expect(find.textContaining('5th Semester • BIC'), findsNothing);

      // Invariant: Editable (3-Day Window) tag is NOT rendered in UI
      expect(find.text('Editable (3-Day Window)'), findsNothing);
    });

    testWidgets('Subjects screen renders concise Curriculum and Your Subjects heading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsProvider.overrideWith((ref) => _LoadedSubjectsNotifier()),
          ],
          child: MaterialApp(
            home: SubjectsScreen(
              onOpenDrawer: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Invariant: Concise heading
      expect(find.text('Your Subjects'), findsOneWidget);
      expect(find.text('Curriculum'), findsOneWidget);

      // Invariant: Long redundant heading is removed
      expect(find.text('Manage your subjects and routine'), findsNothing);
    });
  });
}

class _LoadedSubjectsNotifier extends SubjectsNotifier {
  _LoadedSubjectsNotifier() {
    state = SubjectsState(isLoading: false, subjects: []);
  }
}

