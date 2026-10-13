import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendhub/core/storage/local_storage.dart';
import 'package:attendhub/shared/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AttendHub Session Persistence & LocalStorage Tests', () {
    test('Tokens are persisted and retrieved correctly', () async {
      final storage = LocalStorage();
      await storage.saveTokens(
        accessToken: 'test_access_jwt_123',
        refreshToken: 'test_refresh_jwt_456',
      );

      final access = await storage.getAccessToken();
      final refresh = await storage.getRefreshToken();

      expect(access, 'test_access_jwt_123');
      expect(refresh, 'test_refresh_jwt_456');
    });

    test('User profile is cached and retrieved on app restart', () async {
      final storage = LocalStorage();
      final user = UserModel(
        id: 'user_uuid_999',
        email: 'dhiman@adtu.edu.in',
        fullName: 'Dhiman Saikia',
        avatarInitial: 'D',
        isActive: true,
      );

      await storage.saveUser(user);
      final cached = await storage.getCachedUser();

      expect(cached, isNotNull);
      expect(cached!.id, 'user_uuid_999');
      expect(cached.email, 'dhiman@adtu.edu.in');
      expect(cached.fullName, 'Dhiman Saikia');
      expect(cached.avatarInitial, 'D');
      expect(cached.isActive, isTrue);
    });

    test('Onboarding state persists across app starts', () async {
      final storage = LocalStorage();
      expect(await storage.hasOnboarded(), isFalse);

      await storage.setOnboarded(true);
      expect(await storage.hasOnboarded(), isTrue);
    });

    test('clearAuth removes tokens and cached user profile', () async {
      final storage = LocalStorage();
      await storage.saveTokens(
        accessToken: 'access_to_be_cleared',
        refreshToken: 'refresh_to_be_cleared',
      );
      await storage.saveUser(UserModel(
        id: 'to_clear',
        email: 'clear@adtu.edu.in',
        fullName: 'Clear User',
        avatarInitial: 'C',
        isActive: true,
      ));

      await storage.clearAuth();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getCachedUser(), isNull);
      final nav = await storage.getNavState();
      expect(nav.tabIndex, 0);
      expect(nav.secondaryRoute, isNull);
    });

    test('Navigation state persists active tab and secondary route', () async {
      final storage = LocalStorage();

      // Default state
      var nav = await storage.getNavState();
      expect(nav.tabIndex, 0);
      expect(nav.secondaryRoute, isNull);

      // Save secondary route
      await storage.saveNavState(secondaryRoute: 'profile');
      nav = await storage.getNavState();
      expect(nav.tabIndex, 0);
      expect(nav.secondaryRoute, 'profile');

      // Save tab index switch
      await storage.saveNavState(tabIndex: 2, secondaryRoute: null);
      nav = await storage.getNavState();
      expect(nav.tabIndex, 2);
      expect(nav.secondaryRoute, isNull);

      // Clear navigation state
      await storage.clearNavState();
      nav = await storage.getNavState();
      expect(nav.tabIndex, 0);
      expect(nav.secondaryRoute, isNull);
    });

    test('Academic setup draft persists and handles ID mismatch via fallbacks', () async {
      final storage = LocalStorage();

      final draftData = {
        'current_step': 1,
        'full_name': 'Aarav Sharma',
        'university_name': 'IIT Guwahati',
        'course_name': 'B.Tech CSE',
        'subjects': [
          {'name': 'Algorithms', 'code': 'CS-201', 'faculty': 'Dr. Sen', 'color': '#C96E5B'}
        ],
      };

      // 1. Save draft under 'default' (e.g. before auth finishes)
      await storage.saveAcademicSetupDraft('default', draftData);

      // 2. Fetch with newly authenticated UUID -> should seamlessly restore via fallback
      final retrievedWithUuid = await storage.getAcademicSetupDraft('authenticated_uuid_123');
      expect(retrievedWithUuid, isNotNull);
      expect(retrievedWithUuid!['current_step'], 1);
      expect(retrievedWithUuid['university_name'], 'IIT Guwahati');

      // 3. Save draft with UUID
      draftData['current_step'] = 2;
      draftData['university_name'] = 'Updated University';
      await storage.saveAcademicSetupDraft('authenticated_uuid_123', draftData);

      // 4. Fetch with 'default' -> should also seamlessly restore via latest fallback
      final retrievedWithDefault = await storage.getAcademicSetupDraft('default');
      expect(retrievedWithDefault, isNotNull);
      expect(retrievedWithDefault!['current_step'], 2);
      expect(retrievedWithDefault['university_name'], 'Updated University');

      // 5. Clear draft
      await storage.clearAcademicSetupDraft('authenticated_uuid_123');
      expect(await storage.getAcademicSetupDraft('authenticated_uuid_123'), isNull);
      expect(await storage.getAcademicSetupDraft('default'), isNull);
    });

    test('Stale-While-Revalidate cache persists dashboard/analytics and clears on semester switch', () async {
      final storage = LocalStorage();

      await storage.saveCachedDashboard({
        'user_name': 'Dhiman',
        'overall_percentage': 85.0,
      });
      await storage.saveCachedAnalytics({
        'semester_label': 'Semester 4',
        'overall_percentage': 85.0,
      });

      expect(storage.getCachedDashboardSync()?['user_name'], 'Dhiman');
      expect(storage.getCachedAnalyticsSync()?['semester_label'], 'Semester 4');

      // Switching semesters must isolate and purge semester-scoped SWR cache
      await storage.clearSemesterCache();
      expect(storage.getCachedDashboardSync(), isNull);
      expect(storage.getCachedAnalyticsSync(), isNull);
    });
  });
}
