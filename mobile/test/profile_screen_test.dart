import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendhub/core/theme/app_theme.dart';
import 'package:attendhub/features/profile/profile_screen.dart';
import 'package:attendhub/features/profile/providers/profile_provider.dart';
import 'package:attendhub/shared/models/user_model.dart';
import 'package:attendhub/shared/models/semester_model.dart';
import 'package:attendhub/shared/providers/semesters_provider.dart';

class FakeSemestersNotifier extends StateNotifier<SemestersState> implements SemestersNotifier {
  FakeSemestersNotifier(super.initialState);

  @override
  Future<void> loadSemesters() async {}

  @override
  Future<bool> switchSemester(String semesterId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProfileScreen Inline Editing & Section Order Tests', () {
    final mockProfile = AcademicProfileModel(
      id: 'prof-1',
      userId: 'user-1',
      fullName: 'Dhiman Saikia',
      email: 'dhiman@example.com',
      universityName: 'Assam Engineering College',
      courseName: 'Computer Science and Engineering',
      studentIdNumber: 'CSE-2024-042',
      academicDurationYears: 4,
      academicSessionStart: 2024,
      academicSessionEnd: 2028,
      currentSemesterId: 'sem-5',
      currentSemesterLabel: '5th Semester',
      minimumAttendance: 75.0,
      personalTarget: 75.0,
      lowAttendanceAlert: 70.0,
    );

    final mockSemester = SemesterModel(
      id: 'sem-5',
      userId: 'user-1',
      semesterNumber: 5,
      label: '5th Semester',
      startDate: '2026-08-01',
      endDate: '2026-12-20',
      status: 'ACTIVE',
      isActive: true,
      totalWeeks: 16,
      currentWeek: 12,
      weeksRemaining: 4,
      progressPercentage: 75.0,
    );

    testWidgets('ProfileScreen renders Academic Setup just above Attendance Settings and displays Semester Timeline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => Future.value(mockProfile)),
            semestersProvider.overrideWith(
              (ref) => FakeSemestersNotifier(SemestersState(semesters: [mockSemester])),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ProfileScreen(
              onBack: () {},
              onOpenSetup: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify User Card data (Top card clean read-only overview)
      expect(find.text('Dhiman Saikia'), findsNWidgets(2)); // In Top Card and Academic Info
      expect(find.text('CSE-2024-042'), findsWidgets);
      expect(find.text('Computer Science and Engineering'), findsWidgets);

      // 2. Verify Academic Information Section
      expect(find.text('Academic Information'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Assam Engineering College'), findsOneWidget);
      expect(find.text('Semester Timeline'), findsOneWidget);
      expect(find.text('Semester Dates'), findsNothing);

      // Verify Semester Timeline renders both dates on separate lines with no hyphen separator
      expect(find.text('01 Aug 2026'), findsOneWidget);
      expect(find.text('20 Dec 2026'), findsOneWidget);
      expect(find.text('01 Aug 2026 – 20 Dec 2026'), findsNothing);

      // 3. Verify Academic Setup Card exists and is positioned between Academic Info and System Configurations
      expect(find.text('Academic Setup'), findsOneWidget);
      expect(find.text('System Configurations'), findsOneWidget);
      expect(find.text('Timing Format'), findsOneWidget);
      expect(find.text('12-hour'), findsOneWidget);
      expect(find.text('24-hour'), findsOneWidget);

      final academicInfoY = tester.getTopLeft(find.text('Academic Information')).dy;
      final academicSetupY = tester.getTopLeft(find.text('Academic Setup')).dy;
      final systemConfigY = tester.getTopLeft(find.text('System Configurations')).dy;

      // Academic Setup must be below Academic Info and above System Configurations
      expect(academicSetupY, greaterThan(academicInfoY));
      expect(academicSetupY, lessThan(systemConfigY));

      // 4. Verify pencil icons are rendered in Academic Information & System Configurations
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });

    testWidgets('Tapping pencil icon opens inline TextField with text pre-selected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => Future.value(mockProfile)),
            semestersProvider.overrideWith(
              (ref) => FakeSemestersNotifier(SemestersState(semesters: [mockSemester])),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ProfileScreen(
              onBack: () {},
              onOpenSetup: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap pencil for University row
      final uniRow = find.text('Assam Engineering College');
      expect(uniRow, findsOneWidget);
      await tester.tap(uniRow);
      await tester.pumpAndSettle();

      // Inline TextField is rendered
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, 'Assam Engineering College');
      // Verify text selection covers the whole text
      expect(textField.controller?.selection.baseOffset, 0);
      expect(textField.controller?.selection.extentOffset, 'Assam Engineering College'.length);
    });
  });
}
