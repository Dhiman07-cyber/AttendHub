import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendhub/features/onboarding/onboarding_screen.dart';
import 'package:attendhub/features/auth/auth_screen.dart';
import 'package:attendhub/features/auth/providers/auth_provider.dart';
import 'package:attendhub/shared/widgets/landscape_header.dart';
import 'package:attendhub/core/theme/app_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier() {
    state = AuthState(isAuthenticated: false, isLoading: false);
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('AttendHub Onboarding & Landing Slideshow Widget Tests', () {
    testWidgets('Slide 1 renders branding, hero image, and 4 feature badges',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool signInCalled = false;
      bool skipCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OnboardingScreen(
            onFinish: () {},
            onSignIn: () => signInCalled = true,
            onSkip: () => skipCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify branding and heading
      expect(find.text('AttendiFy'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // RichText check
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Track Every Class') &&
            w.text.toPlainText().contains('75%')),
        findsOneWidget,
      );

      // Verify 4 Feature badges
      expect(find.text('Track Attendance'), findsOneWidget);
      expect(find.text('Smart Analytics'), findsOneWidget);
      expect(find.text('Manage Holidays'), findsOneWidget);
      expect(find.text('Organize Subjects'), findsOneWidget);

      // Verify CTA button and Sign In link
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Test Sign In tap
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(signInCalled, isTrue);

      // Test Skip tap
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(skipCalled, isTrue);
    });

    testWidgets(
        'Navigation advances through Slide 2 and Slide 3 with universal subjects and steps back smoothly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool createAccountCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OnboardingScreen(
            onFinish: () {},
            onSignIn: () {},
            onCreateAccount: () => createAccountCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1 -> Tap "Get Started"
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Now on Slide 2
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.textContaining('Smart Analytics'), findsWidgets);
      // 5 Relatable Class 10 / College subjects check
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Computer Applications'), findsOneWidget);
      expect(find.text('English & Communication'), findsOneWidget);
      expect(find.text('Science & Lab'), findsOneWidget);
      expect(find.text('Social Studies'), findsOneWidget);
      expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Slide 2 -> Tap "Next"
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Now on Slide 3
      expect(find.text('3 / 3'), findsOneWidget);
      expect(find.textContaining('Plan Your Semester'), findsOneWidget);
      expect(find.text('Upload Routine'), findsOneWidget);
      expect(find.text('Add Manually'), findsOneWidget);
      expect(find.text('Quick and easy setup'), findsOneWidget);
      expect(find.textContaining('Holiday protection'), findsNothing);
      expect(find.text('Create Account'), findsOneWidget);

      // Test stepping backward from Slide 3 to Slide 2 using top bar back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      // Test stepping backward from Slide 2 to Slide 1 using top bar back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.text('AttendHub'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Move forward again to Slide 3 and complete
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap "Create Account"
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      expect(createAccountCalled, isTrue);
    });
  });

  group('AttendHub AuthScreen Widget Tests', () {
    testWidgets('Renders header, back button, login inputs and social options',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool backCalled = false;

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
              onBack: () => backCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top title and subtitle
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Log in to continue to AttendiFy'), findsOneWidget);

      // Fields
      expect(find.text('Email / University ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);

      // Social button (Google only)
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with GitHub'), findsNothing);
      expect(find.text('Continue with Microsoft'), findsNothing);

      // Switch to Sign Up
      final signUpFinder = find.text('Sign Up');
      await tester.ensureVisible(signUpFinder);
      await tester.tap(signUpFinder);
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);

      // Back button
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(backCalled, isTrue);
    });
  });

  group('AttendHub LandscapeHeaderWidget Hero Tests', () {
    testWidgets(
        'Renders greeting, user name, semester info and header actions (bell and avatar)',
        (WidgetTester tester) async {
      bool bellTapped = false;
      bool avatarTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: LandscapeHeaderWidget(
              greeting: 'Good morning,',
              userName: 'Dhiman',
              semesterInfo: '5th Semester • CSE',
              avatarInitial: 'D',
              showActions: true,
              onNotificationTap: () => bellTapped = true,
              onAvatarTap: () => avatarTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check text rendering
      expect(find.text('Good morning,'), findsOneWidget);
      expect(find.text('Dhiman'), findsOneWidget);
      expect(find.text('5th Semester • CSE'), findsOneWidget);

      // Check notification bell with red badge
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();
      expect(bellTapped, isTrue);

      // Check avatar circle with initial 'D'
      expect(find.text('D'), findsOneWidget);
      await tester.tap(find.text('D'));
      await tester.pumpAndSettle();
      expect(avatarTapped, isTrue);

      // Verify Image.asset is present in widget tree
      expect(find.byType(Image), findsOneWidget);
    });
  });
}

