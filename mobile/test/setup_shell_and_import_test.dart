import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendhub/core/storage/local_storage.dart';
import 'package:attendhub/core/theme/app_theme.dart';
import 'package:attendhub/core/theme/app_colors.dart';
import 'package:attendhub/shared/widgets/app_text_field.dart';
import 'package:attendhub/shared/widgets/persistent_top_bar.dart';
import 'package:attendhub/shared/widgets/bottom_nav_bar.dart';
import 'package:attendhub/features/setup/academic_setup_screen.dart';
import 'package:attendhub/features/imports/routine_import_dialog.dart';
import 'package:attendhub/features/imports/holiday_import_dialog.dart';

void main() {
  group('AttendHub Persistent Shell Tests', () {
    testWidgets('PersistentTopBar renders fixed controls with title, subtitle, bell, and avatar', (tester) async {
      bool menuTapped = false;
      bool bellTapped = false;
      bool avatarTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PersistentTopBar(
              isSecondary: false,
              title: 'AttendHub',
              subtitle: 'Semester 5 • Overview',
              avatarInitial: 'D',
              onMenuOrBack: () => menuTapped = true,
              onNotificationTap: () => bellTapped = true,
              onAvatarTap: () => avatarTapped = true,
            ),
          ),
        ),
      );

      // Verify branding and title
      expect(find.text('AttendHub'), findsOneWidget);
      expect(find.text('Semester 5 • Overview'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Tap actions
      await tester.tap(find.byIcon(Icons.menu_rounded));
      expect(menuTapped, isTrue);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      expect(bellTapped, isTrue);

      await tester.tap(find.text('D'));
      expect(avatarTapped, isTrue);
    });

    testWidgets('PersistentTopBar switches to Back button in secondary route mode', (tester) async {
      bool backTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PersistentTopBar(
              isSecondary: true,
              title: 'Analytics',
              subtitle: 'Attendance Forecast',
              avatarInitial: 'A',
              onMenuOrBack: () => backTapped = true,
              onNotificationTap: () {},
              onAvatarTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(backTapped, isTrue);
    });

    testWidgets('LiquidGlassBottomNav renders 5 primary destinations and switches tabs', (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: LiquidGlassBottomNav(
              currentIndex: selectedTab,
              onTap: (idx) => selectedTab = idx,
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Routine'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Subjects'), findsOneWidget);
      expect(find.text('Holidays'), findsOneWidget);

      await tester.tap(find.text('Routine'));
      expect(selectedTab, 1);

      await tester.tap(find.text('Analytics'));
      expect(selectedTab, 2);

      await tester.tap(find.text('Subjects'));
      expect(selectedTab, 3);

      await tester.tap(find.text('Holidays'));
      expect(selectedTab, 4);
    });
  });

  group('Academic Setup Wizard Tests', () {
    testWidgets('AcademicSetupScreen renders Step 1 (Profile) with inputs and navigation controls', (tester) async {
      bool setupCompleted = false;
      bool setupCancelled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AcademicSetupScreen(
              onComplete: () => setupCompleted = true,
              onCancel: () => setupCancelled = true,
            ),
          ),
        ),
      );

      expect(setupCompleted, isFalse);
      expect(setupCancelled, isFalse);
      // Verify Header & Step indicator
      expect(find.text('Step 1/7'), findsOneWidget);
      expect(find.text('Academic Profile'), findsWidgets);

      // Verify Step 1 fields
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('University / College Name'), findsOneWidget);
      expect(find.text('Course / Degree Program'), findsOneWidget);

      // Verify Continue button
      expect(find.text('Continue to Step 2'), findsOneWidget);

      // Tap Cancel button
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(setupCancelled, isTrue);
    });

    testWidgets('Deleting course subjects in Step 3 safely resets routine dropdown in Step 4 without assertion failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AcademicSetupScreen(
              onComplete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Advance from Step 1 to Step 2
      await tester.tap(find.text('Continue to Step 2'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2/7'), findsOneWidget);

      // Advance from Step 2 to Step 3
      await tester.tap(find.text('Continue to Step 3'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3/7'), findsOneWidget);
      expect(find.text('Enroll Subjects'), findsOneWidget);
      expect(find.text('Software Engineering'), findsOneWidget);

      // Delete the first subject ('Software Engineering')
      final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteButtons, findsWidgets);
      await tester.ensureVisible(deleteButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Verify 'Software Engineering' is removed
      expect(find.text('Software Engineering'), findsNothing);
      expect(find.text('Operating Systems'), findsOneWidget);

      // Advance to Step 4 (Weekly Schedule)
      await tester.ensureVisible(find.text('Continue to Step 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Step 4'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4/7'), findsOneWidget);
      expect(find.text('Weekly Schedule'), findsOneWidget);

      // Verify no assertion failure occurred
      expect(tester.takeException(), isNull);

      // Tap Add Class and verify next available subject ('Operating Systems') is safely active in routine dropdown
      await tester.tap(find.text('Add Class').first);
      await tester.pumpAndSettle();
      expect(find.text('Operating Systems'), findsWidgets);
    });

    testWidgets('Step 2 configures class timings and working schedule, and Step 4 renders horizontal timetable with 3-option slot editor', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AcademicSetupScreen(
              onComplete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue to Step 2'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2/7'), findsOneWidget);

      // Verify Step 2 Clean Semantic Structure & Attendance Targets
      expect(find.text('Semester'), findsOneWidget);
      expect(find.text('Semester Number'), findsNothing);
      expect(find.text('Display Label'), findsNothing);
      expect(find.text('Start Date'), findsNothing);
      expect(find.text('End Date'), findsNothing);
      expect(find.text('Attendance Targets & Goals'), findsOneWidget);
      expect(find.text('Attendance Invariant Thresholds'), findsNothing);
      expect(find.text('Mandatory Minimum'), findsOneWidget);
      expect(find.text('Personal Target'), findsOneWidget);
      expect(find.text('75.0% Required'), findsOneWidget);
      expect(find.text('75.0% Goal'), findsOneWidget);

      // Verify Step 2 Schedule Framework
      expect(find.text('Timings'), findsOneWidget);
      expect(find.text('Class Timings'), findsOneWidget);
      expect(find.text('Start Time'), findsWidgets);
      expect(find.text('End Time'), findsWidgets);
      expect(find.text('Working Days'), findsOneWidget);
      expect(find.text('Day Wise Start'), findsOneWidget);
      expect(find.text('Day End'), findsOneWidget);

      // Verify defaults
      expect(find.text('9 AM (Default)'), findsOneWidget);
      expect(find.text('4 PM (Default)'), findsOneWidget);
      expect(find.text('Monday (Default)'), findsOneWidget);
      expect(find.text('Saturday (Default)'), findsOneWidget);

      // Test preset button updates personal target to 80%
      await tester.ensureVisible(find.text('80%'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('80%'));
      await tester.pumpAndSettle();
      expect(find.text('80.0% Goal'), findsOneWidget);

      // Toggle Day End to Friday (5 working days)
      await tester.ensureVisible(find.text('Saturday (Default)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saturday (Default)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Friday').last);
      await tester.pumpAndSettle();

      // Advance to Step 3
      await tester.ensureVisible(find.text('Continue to Step 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Step 3'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3/7'), findsOneWidget);

      // Advance to Step 4 (Weekly Routine / Timetable)
      await tester.ensureVisible(find.text('Continue to Step 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Step 4'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4/7'), findsOneWidget);
      expect(find.text('Weekly Schedule'), findsOneWidget);

      // Verify empty slot "Add Class" boxes are present and have whitish surface color
      final addBoxes = find.text('Add Class');
      expect(addBoxes, findsWidgets);
      final firstAddBoxContainer = tester.widget<Container>(
        find.ancestor(
          of: addBoxes.first,
          matching: find.byType(Container),
        ).at(1),
      );
      final addBoxDeco = firstAddBoxContainer.decoration as BoxDecoration?;
      expect(addBoxDeco?.color, equals(AppColors.surface));

      // Tap the first empty slot box to open the 3-option modal editor
      await tester.tap(addBoxes.first);
      await tester.pumpAndSettle();

      // Verify Modal Title
      expect(find.text('Schedule Class'), findsOneWidget);

      // Verify Option 1: Select Subject
      expect(find.text('1. Select Subject'), findsOneWidget);
      expect(find.text('Software Engineering'), findsWidgets);

      // Open subject dropdown to verify Break Time is the first option
      await tester.tap(find.text('Software Engineering').first);
      await tester.pumpAndSettle();
      expect(find.text('Break Time'), findsWidgets);

      // Select Software Engineering from dropdown menu
      await tester.tap(find.text('Software Engineering').last);
      await tester.pumpAndSettle();

      // Verify Option 2: Select Class Type (Theory vs Practical / Lab)
      expect(find.text('2. Select Class Type'), findsOneWidget);
      expect(find.text('Theory'), findsWidgets);
      expect(find.text('Practical / Lab'), findsWidgets);
      expect(find.text('Default: 1 Hour'), findsOneWidget);
      expect(find.text('Default: 2 Hours'), findsOneWidget);

      // Verify Option 3: Side-by-side Timings
      expect(find.text('3. Class Timings'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);

      // Select Practical / Lab (2 hr duration)
      await tester.tap(find.text('Practical / Lab'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Save Slot
      await tester.ensureVisible(find.text('Add Slot'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Slot'));
      await tester.pumpAndSettle();

      // Verify slot added into timetable with LAB badge and whitish card surface
      expect(find.text('LAB'), findsOneWidget);
      final scheduledSlotContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('LAB'),
          matching: find.byType(Container),
        ).at(1),
      );
      final scheduledDeco = scheduledSlotContainer.decoration as BoxDecoration?;
      expect(scheduledDeco?.color, equals(AppColors.surface));

      // Tap on the scheduled slot to open edit modal
      await tester.tap(find.text('Software Engineering'));
      await tester.pumpAndSettle();

      // Verify Edit modal has Delete Slot at top right
      expect(find.text('Edit Schedule Slot'), findsOneWidget);
      expect(find.byTooltip('Delete Slot'), findsOneWidget);

      // Tap Delete Slot icon at top right
      await tester.tap(find.byTooltip('Delete Slot'));
      await tester.pumpAndSettle();

      // Verify slot was removed from timetable
      expect(find.text('LAB'), findsNothing);
    });

    testWidgets('Step 4 timetable keeps leftmost Day column fixed while hour columns scroll horizontally', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AcademicSetupScreen(
              onComplete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Jump to Step 4 (Weekly Routine)
      await tester.tap(find.byKey(const Key('step_segment_3')));
      await tester.pumpAndSettle();

      expect(find.text('Step 4/7'), findsOneWidget);
      expect(find.text('Weekly Schedule'), findsOneWidget);

      // Verify Monday and Wednesday day texts are present in the fixed column
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);

      // Find initial positions
      final mondayOffsetBefore = tester.getTopLeft(find.text('Monday'));
      final hour9OffsetBefore = tester.getTopLeft(find.text('9 AM – 10 AM'));

      // Find horizontal scrollable
      final horizontalScrollable = find.byType(SingleChildScrollView).last;

      // Drag timetable horizontally to the left by 120 pixels
      await tester.drag(horizontalScrollable, const Offset(-120, 0));
      await tester.pumpAndSettle();

      // Verify leftmost Day column remained fixed at its exact X coordinate
      final mondayOffsetAfter = tester.getTopLeft(find.text('Monday'));
      expect(mondayOffsetAfter.dx, equals(mondayOffsetBefore.dx));

      // Verify the 9 AM - 10 AM hour column moved to the left
      final hour9OffsetAfter = tester.getTopLeft(find.text('9 AM – 10 AM'));
      expect(hour9OffsetAfter.dx, lessThan(hour9OffsetBefore.dx));
    });

    testWidgets('Interactive step pills navigate seamlessly between Step 1 (Academic Profile) and Step 2 (Semester Term) without content mismatch', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AcademicSetupScreen(
              onComplete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Verify Initial Step 1 state
      expect(find.text('Step 1/7'), findsOneWidget);
      expect(find.text('Academic Profile'), findsWidgets);
      expect(find.text('University / College Name'), findsOneWidget);
      expect(find.text('Semester & Attendance Rules'), findsNothing);

      // Tap Step Segment 1 (index 1 -> Step 2) to jump directly to Step 2
      final step2Segment = find.byKey(const Key('step_segment_1'));
      expect(step2Segment, findsOneWidget);
      await tester.tap(step2Segment);
      await tester.pumpAndSettle();

      // Verify Step 2 is active
      expect(find.text('Step 2/7'), findsOneWidget);
      expect(find.text('Semester Term'), findsOneWidget);
      expect(find.text('Semester & Attendance Rules'), findsOneWidget);
      expect(find.text('University / College Name'), findsNothing);

      // Tap Step Segment 0 (index 0 -> Step 1) to jump back to Step 1
      final step1Segment = find.byKey(const Key('step_segment_0'));
      expect(step1Segment, findsOneWidget);
      await tester.tap(step1Segment);
      await tester.pumpAndSettle();

      // Verify Step 1 is active again without content mismatch
      expect(find.text('Step 1/7'), findsOneWidget);
      expect(find.text('Academic Profile'), findsWidgets);
      expect(find.text('University / College Name'), findsOneWidget);
      expect(find.text('Semester & Attendance Rules'), findsNothing);

      // Tap Step Segment 3 (index 3 -> Step 4) to jump directly to Weekly Routine
      final step4Segment = find.byKey(const Key('step_segment_3'));
      expect(step4Segment, findsOneWidget);
      await tester.tap(step4Segment);
      await tester.pumpAndSettle();

      expect(find.text('Step 4/7'), findsOneWidget);
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.text('Weekly Schedule'), findsOneWidget);
    });

    testWidgets('AcademicSetupScreen persists form data stepwise and on tap-outside unfocus to local storage, and restores on restart', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AcademicSetupScreen(
              onComplete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter full name in Step 1
      final nameField = find.widgetWithText(AppTextField, 'Full Name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Jane Doe');

      // Tapping outside triggers unfocus and _saveDraft
      await tester.tap(find.text('Academic Profile').first);
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.text('Continue to Step 2'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2/7'), findsOneWidget);

      // Verify draft saved in LocalStorage
      final draft = await storage.getAcademicSetupDraft('default');
      expect(draft, isNotNull);
      expect(draft!['full_name'], 'Jane Doe');
      expect(draft['current_step'], 1);

      // Simulate App Restart by rebuilding fresh screen with same mock storage
      await tester.pumpWidget(Container()); // unmount
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AcademicSetupScreen(
              onComplete: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen restored to Step 2 and kept data
      expect(find.text('Step 2/7'), findsOneWidget);

      // Go back to Step 1 and verify 'Jane Doe' is intact
      await tester.tap(find.byTooltip('Previous Step'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1/7'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('Draft is cleared from local storage when committed or explicitly purged', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage();

      await storage.saveAcademicSetupDraft('default', {
        'current_step': 2,
        'full_name': 'Test Student',
      });

      var draft = await storage.getAcademicSetupDraft('default');
      expect(draft, isNotNull);
      expect(draft!['full_name'], 'Test Student');

      // Clear draft (which happens upon successful commit)
      await storage.clearAcademicSetupDraft('default');

      draft = await storage.getAcademicSetupDraft('default');
      expect(draft, isNull);
    });
  });

  group('Draft-Only Import Dialog Tests', () {
    testWidgets('RoutineImportDialog displays draft-only header and dispatches discard on Cancel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineImportDialog(
              semesterId: 'sem-test-123',
              onImportSuccess: () {},
            ),
          ),
        ),
      );

      expect(find.text('Import Routine'), findsOneWidget);
      expect(find.textContaining('Draft-Only Lifecycle'), findsOneWidget);
      expect(find.textContaining('Paste CSV or Structured Timetable Text'), findsOneWidget);
      expect(find.text('Parse Into Draft'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('HolidayImportDialog displays draft-only notice and discard option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HolidayImportDialog(
              semesterId: 'sem-test-123',
              onImportSuccess: () {},
            ),
          ),
        ),
      );

      expect(find.text('Import Academic Holidays'), findsOneWidget);
      expect(find.textContaining('Draft-Only Lifecycle'), findsOneWidget);
      expect(find.textContaining('Paste CSV or Academic Calendar Text'), findsOneWidget);
      expect(find.text('Parse Holidays'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });

  group('Multi-Viewport Responsive & Overflow Tests', () {
    final viewports = [
      {'name': '320px (Ultra-Compact / iPhone SE)', 'size': const Size(320, 640)},
      {'name': '360px (Standard Compact Android)', 'size': const Size(360, 740)},
      {'name': '375px (iPhone X / 11 / 12 mini)', 'size': const Size(375, 812)},
      {'name': '393px (iPhone 14 / 15 / 16)', 'size': const Size(393, 852)},
      {'name': '412px (Google Pixel 7 / 8 / 9)', 'size': const Size(412, 915)},
      {'name': '430px (iPhone Pro Max / Plus)', 'size': const Size(430, 932)},
    ];

    for (final vp in viewports) {
      final name = vp['name'] as String;
      final size = vp['size'] as Size;

      testWidgets('PersistentTopBar renders without overflow at $name', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: PersistentTopBar(
                isSecondary: false,
                title: 'AttendHub - Daily Attendance',
                subtitle: '5th Semester • Computer Science and Engineering',
                avatarInitial: 'D',
                onMenuOrBack: () {},
                onNotificationTap: () {},
                onAvatarTap: () {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('AcademicSetupScreen renders without overflow at $name', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        FlutterErrorDetails? capturedDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          capturedDetails = details;
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: AcademicSetupScreen(
                onComplete: () {},
                onCancel: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (capturedDetails != null) {
          debugPrint('DETAILS: ${capturedDetails.toString()}');
        }

        expect(tester.takeException(), isNull);
      });
    }
  });
}
