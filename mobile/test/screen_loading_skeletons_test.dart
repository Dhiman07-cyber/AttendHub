import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendhub/core/theme/app_theme.dart';
import 'package:attendhub/features/today/today_screen.dart';
import 'package:attendhub/features/today/providers/today_provider.dart';
import 'package:attendhub/features/subjects/subjects_screen.dart';
import 'package:attendhub/features/subjects/providers/subjects_provider.dart';
import 'package:attendhub/features/holidays/holidays_screen.dart';
import 'package:attendhub/features/holidays/providers/holidays_provider.dart';
import 'package:attendhub/features/analytics/analytics_screen.dart';
import 'package:attendhub/features/analytics/providers/analytics_provider.dart';
import 'package:attendhub/shared/models/analytics_model.dart';
import 'package:attendhub/features/calendar/calendar_screen.dart';
import 'package:attendhub/features/calendar/providers/calendar_provider.dart';
import 'package:attendhub/shared/widgets/shimmer_skeleton.dart';

class _FakeLoadingTodayNotifier extends TodayNotifier {
  _FakeLoadingTodayNotifier() {
    state = TodayState(
      isLoading: true,
      hasLoaded: false,
      dateStr: 'Today',
      semesterLabel: 'Active Semester',
      sessions: [],
      timetableEntries: [],
    );
  }

  @override
  Future<void> loadToday({int? offset}) async {}
}

class _FakeLoadingSubjectsNotifier extends SubjectsNotifier {
  _FakeLoadingSubjectsNotifier() {
    state = SubjectsState(
      isLoading: true,
      hasLoaded: false,
      subjects: [],
    );
  }

  @override
  Future<void> loadSubjects() async {}
}

class _FakeLoadingHolidaysNotifier extends HolidaysNotifier {
  _FakeLoadingHolidaysNotifier() {
    state = HolidaysState(
      isLoading: true,
      hasLoaded: false,
      holidays: [],
    );
  }

  @override
  Future<void> loadHolidays() async {}
}

class _FakeLoadingCalendarNotifier extends CalendarNotifier {
  _FakeLoadingCalendarNotifier() {
    state = CalendarState(
      year: 2026,
      month: 10,
      monthName: 'October',
      selectedDay: 15,
      days: [],
      selectedDateSessions: [],
      selectedDateHolidays: [],
      isLoading: true,
      hasLoaded: false,
    );
  }

  @override
  Future<void> loadCalendar({int? targetYear, int? targetMonth, int? targetDay}) async {}
}

void main() {
  group('Screen Loading Skeletons Tests — No premature timetable setup flash', () {
    testWidgets('TodayScreen renders ShimmerLoading skeleton while loading and never flashes timetable setup prompt', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayProvider.overrideWith((ref) => _FakeLoadingTodayNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: TodayScreen(onOpenDrawer: () {}),
          ),
        ),
      );

      // Verify shimmer loading skeleton is present
      expect(find.byType(ShimmerLoading), findsWidgets);
      // Verify "Your timetable isn't set up yet" is strictly NOT present
      expect(find.text("Your timetable isn't set up yet."), findsNothing);
      expect(find.text('Set Up Timetable'), findsNothing);
    });

    testWidgets('SubjectsScreen renders ShimmerLoading skeleton while loading and never flashes timetable setup prompt', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsProvider.overrideWith((ref) => _FakeLoadingSubjectsNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: SubjectsScreen(onOpenDrawer: () {}),
          ),
        ),
      );

      // Verify shimmer loading skeleton is present
      expect(find.byType(ShimmerLoading), findsWidgets);
      // Verify "Your timetable isn't set up yet" is strictly NOT present
      expect(find.text("Your timetable isn't set up yet."), findsNothing);
      expect(find.text('Set Up Timetable'), findsNothing);
    });

    testWidgets('HolidaysScreen renders ShimmerLoading skeleton while loading and never flashes timetable setup prompt', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            holidaysProvider.overrideWith((ref) => _FakeLoadingHolidaysNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: HolidaysScreen(
              onOpenDrawer: () {},
              onNavigateToCalendar: () {},
            ),
          ),
        ),
      );

      // Verify shimmer loading skeleton is present
      expect(find.byType(ShimmerLoading), findsWidgets);
      // Verify "Your timetable isn't set up yet" is strictly NOT present
      expect(find.text("Your timetable isn't set up yet."), findsNothing);
      expect(find.text('Set Up Timetable'), findsNothing);
    });

    testWidgets('CalendarScreen renders ShimmerLoading skeleton while loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            calendarProvider.overrideWith((ref) => _FakeLoadingCalendarNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CalendarScreen(
              onOpenDrawer: () {},
              onNavigateToHolidays: () {},
            ),
          ),
        ),
      );

      // Verify shimmer loading skeleton is present
      expect(find.byType(ShimmerLoading), findsWidgets);
    });

    testWidgets('AnalyticsScreen renders ShimmerLoading skeleton while loading and never flashes timetable setup prompt', (tester) async {
      final completer = Completer<AnalyticsOverviewModel>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsProvider.overrideWith((ref) => completer.future),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AnalyticsScreen(onOpenDrawer: () {}),
          ),
        ),
      );

      // Verify shimmer loading skeleton is present
      expect(find.byType(ShimmerLoading), findsWidgets);
      // Verify "Your timetable isn't set up yet" is strictly NOT present
      expect(find.text("Your timetable isn't set up yet."), findsNothing);
      expect(find.text('Set Up Timetable'), findsNothing);
    });
  });
}
