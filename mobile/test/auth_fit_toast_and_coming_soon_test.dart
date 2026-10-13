import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendhub/features/auth/auth_screen.dart';
import 'package:attendhub/features/auth/providers/auth_provider.dart';
import 'package:attendhub/features/subjects/subjects_screen.dart';
import 'package:attendhub/features/subjects/providers/subjects_provider.dart';
import 'package:attendhub/features/holidays/holidays_screen.dart';
import 'package:attendhub/core/theme/app_theme.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier() {
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

class FakeSubjectsNotifier extends SubjectsNotifier {
  FakeSubjectsNotifier() {
    state = SubjectsState(isLoading: false, subjects: []);
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthScreen Fit and Toast Verification', () {
    testWidgets(
        'Login screen fits within standard viewport (390x844) including Continue with Google and footer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AuthScreen(
              initialIsSignUp: false,
              onLoginSuccess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all core elements exist
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Email / University ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);

      // Verify "Continue with Google" is vertically inside the screen without scrolling
      final googleOffset = tester.getTopLeft(find.text('Continue with Google'));
      expect(googleOffset.dy, lessThan(844.0));
      expect(googleOffset.dy, greaterThan(0.0));

      // Verify footer is also vertically on-screen
      final footerOffset = tester.getTopLeft(find.text('Sign Up'));
      expect(footerOffset.dy, lessThan(844.0));
      expect(footerOffset.dy, greaterThan(0.0));
    });

    testWidgets(
        'Login screen fits within compact viewport (375x667) without clipping',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AuthScreen(
              initialIsSignUp: false,
              onLoginSuccess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final googleFinder = find.text('Continue with Google');
      expect(googleFinder, findsOneWidget);
      final googleOffset = tester.getTopLeft(googleFinder);
      expect(googleOffset.dy, lessThan(667.0));
    });

    testWidgets(
        'Empty submit triggers floating Toast instead of in-page error banner',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AuthScreen(
              initialIsSignUp: false,
              onLoginSuccess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Log In with empty email
      await tester.tap(find.text('Log In'));
      await tester.pump();

      // Verify floating SnackBar toast appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Please enter your email address.'), findsOneWidget);

      // Verify icon in toast
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('Coming Soon Button Verification', () {
    testWidgets('SubjectsScreen Upload Routine triggers Coming Soon Toast',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectsProvider.overrideWith((ref) => FakeSubjectsNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: SubjectsScreen(
              onOpenDrawer: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap Upload Routine
      final uploadRoutineFinder = find.text('Upload Routine');
      expect(uploadRoutineFinder, findsOneWidget);
      await tester.tap(uploadRoutineFinder);
      await tester.pump();

      // Verify Coming Soon toast appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Upload Routine is coming soon!'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets(
        'HolidaysScreen Upload Holiday List triggers Coming Soon Toast',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: HolidaysScreen(
              onOpenDrawer: () {},
              onNavigateToCalendar: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap Upload Holiday List
      final uploadHolidayFinder = find.text('Upload Holiday List');
      expect(uploadHolidayFinder, findsOneWidget);
      await tester.tap(uploadHolidayFinder);
      await tester.pump();

      // Verify Coming Soon toast appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Upload Holiday List is coming soon!'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });
  });
}
