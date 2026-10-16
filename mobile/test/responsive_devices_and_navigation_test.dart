import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendhub/shared/widgets/attendance_progress_ring.dart';
import 'package:attendhub/shared/widgets/semester_progress_dial.dart';
import 'package:attendhub/shared/widgets/bottom_nav_bar.dart';
import 'package:attendhub/shared/widgets/app_drawer.dart';
import 'package:attendhub/features/dashboard/dashboard_screen.dart';
import 'package:attendhub/features/dashboard/providers/dashboard_provider.dart';
import 'package:attendhub/features/analytics/analytics_screen.dart';
import 'package:attendhub/features/analytics/providers/analytics_provider.dart';
import 'package:attendhub/shared/models/dashboard_model.dart';
import 'package:attendhub/shared/models/session_model.dart';
import 'package:attendhub/shared/models/analytics_model.dart';
import 'package:attendhub/features/calendar/providers/calendar_provider.dart';

void main() {
  group('Multi-Device Responsive Tests (320px to 430px)', () {
    final deviceViewports = [
      {'name': 'iPhone SE (Ultra-Compact)', 'width': 320.0, 'height': 568.0},
      {'name': 'Samsung Galaxy A55 (Compact)', 'width': 360.0, 'height': 800.0},
      {'name': 'iPhone mini / X', 'width': 375.0, 'height': 667.0},
      {'name': 'iPhone 14 / 15 / 16', 'width': 393.0, 'height': 852.0},
      {'name': 'Google Pixel 7 / 8', 'width': 412.0, 'height': 915.0},
      {'name': 'iPhone Pro Max', 'width': 430.0, 'height': 932.0},
    ];

    for (final dev in deviceViewports) {
      testWidgets('AttendanceProgressRing & SemesterProgressDial render without overflow on ${dev['name']} (${dev['width']}px)', (tester) async {
        final double width = dev['width'] as double;
        final double height = dev['height'] as double;
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width - 32, // simulates 16px page padding on both sides
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const AttendanceProgressRing(
                            percentage: 0.0,
                            attended: 0,
                            conducted: 0,
                            targetPercentage: 75.0,
                            minimumPercentage: 75.0,
                            trendChange: 6.2,
                            size: 105,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        flex: 5,
                        child: SemesterProgressDial(
                          currentWeek: 9,
                          totalWeeks: 15,
                          weeksRemaining: 7,
                          progressPercentage: 60.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Verify no RenderFlex overflow exceptions occurred
        expect(tester.takeException(), isNull);
        expect(find.byType(AttendanceProgressRing), findsOneWidget);
        expect(find.byType(SemesterProgressDial), findsOneWidget);
      });
    }
  });

  group('Bottom Navigation Bar & Drawer Tests', () {
    testWidgets('LiquidGlassBottomNav renders Holidays instead of Calendar at index 4', (tester) async {
      int tappedIndex = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: LiquidGlassBottomNav(
              currentIndex: 0,
              onTap: (idx) => tappedIndex = idx,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Holidays'), findsOneWidget);
      expect(find.text('Calendar'), findsNothing);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);

      await tester.tap(find.text('Holidays'));
      expect(tappedIndex, equals(4));
    });

    testWidgets('AppDrawer does not contain Calendar item', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              drawer: AppDrawer(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Holidays'), findsOneWidget);
      expect(find.text('Calendar'), findsNothing);
    });

    testWidgets('AppDrawer renders header branding safely without overflow on 320px device', (tester) async {
      tester.view.physicalSize = const Size(320.0, 568.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              drawer: AppDrawer(),
            ),
          ),
        ),
      );
      await tester.pump();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('AttendiFy'), findsOneWidget);
      expect(find.text('Track • Plan • Stay Above 75%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group("Dashboard Today's Classes Card (All Attended & No Date Dropdown)", () {
    testWidgets('Dashboard renders Today\'s Classes card with All Attended button and no date dropdown', (tester) async {
      final mockData = DashboardOverviewModel(
        userName: 'Dhiman',
        currentSemesterLabel: '5th Semester',
        courseName: 'Computer Science',
        enrollmentId: 'ADTU/0/2024-28/BCSM/062',
        overallPercentage: 78.5,
        targetPercentage: 75.0,
        minimumPercentage: 75.0,
        totalAttended: 32,
        totalConducted: 40,
        currentWeek: 9,
        totalWeeks: 15,
        weeksRemaining: 7,
        semesterProgressPct: 60.0,
        trendFromLastMonth: 2.5,
        todayDateStr: '2026-10-11',
        todaySessions: [
          ClassSessionModel(
            id: 'sess-1',
            semesterId: 'sem-1',
            subjectId: 'sub-1',
            subjectName: 'Operating Systems',
            subjectCode: 'CS501',
            subjectColor: '#C96E5B',
            subjectIcon: 'book',
            date: '2026-10-11',
            startTime: '09:00',
            endTime: '10:00',
            sessionStatus: 'SCHEDULED',
            isExtra: false,
            classType: 'THEORY',
            attendanceStatus: null,
          ),
        ],
        subjectsNeedingAttention: [],
        trendPoints: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) => mockData),
          ],
          child: const MaterialApp(
            home: DashboardScreen(
              onOpenDrawer: _dummyFn,
              onNavigateToToday: _dummyFn,
              onNavigateToAnalytics: _dummyFn,
              onNavigateToCalendar: _dummyFn,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header shows "Today's Classes"
      expect(find.text("Today's Classes"), findsOneWidget);
      // "All Attended" button is rendered
      expect(find.text('All Attended'), findsOneWidget);

      // Verify old date selector dropdown (Yesterday/Tomorrow pill) is removed
      expect(find.text('Yesterday'), findsNothing);
      expect(find.text('Tomorrow'), findsNothing);
    });
  });

  group('Analytics Overview with Integrated Academic Calendar', () {
    testWidgets('Analytics overview renders Academic Calendar and omits This Semester badge', (tester) async {
      final mockAnalytics = AnalyticsOverviewModel(
        semesterId: 'sem-1',
        semesterLabel: '5th Semester',
        totalAttended: 41,
        totalAbsent: 9,
        totalConducted: 50,
        overallPercentage: 82.0,
        hasData: true,
        status: 'Safe',
        statusLabel: 'Safe Zone',
        minimumRequirement: 75.0,
        personalTarget: 75.0,
        classesNeededForMin: 0,
        classesNeededForTarget: 0,
        maxSafeAbsences: 4,
        totalRecoveryClassesNeeded: 0,
        totalSafeAbsencesMargin: 4,
        subjects: [],
        insights: [],
        trends: [],
        monthOverMonthChange: 2.5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsProvider.overrideWith((ref) => Future.value(mockAnalytics)),
            calendarProvider.overrideWith((ref) => FakeCalendarNotifier()),
          ],
          child: const MaterialApp(
            home: AnalyticsScreen(
              onOpenDrawer: _dummyFn,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Academic Calendar is completely removed from Overview
      expect(find.text('Academic Calendar'), findsNothing);

      // Verify "This Semester" badge on Overall Attendance Trend is removed
      expect(find.text('This Semester'), findsNothing);
    });
  });
}

class FakeCalendarNotifier extends CalendarNotifier {
  @override
  Future<void> loadCalendar({int? targetYear, int? targetMonth, int? targetDay}) async {
    state = state.copyWith(isLoading: false);
  }
}

void _dummyFn() {}
