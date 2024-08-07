import 'package:flutter_test/flutter_test.dart';
import 'package:safety_eye_app/models/Settings.dart';
import 'package:safety_eye_app/services/preferences_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PreferencesService', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    PreferencesService prefService = PreferencesService();

    setUp(() async {
      // Create an instance of the mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('validate set preference', () async {
      // Given
      const key = PreferencesKeys.videoResolution;
      const String expectedValue = 'Low';
      // When
      await prefService.setPref<String>(key, expectedValue);
      // Then
      expect(await prefService.getPrefOrDefault<String>(key), expectedValue);
    });

    test('validate default preference', () async {
      // Given
      final prefService = PreferencesService();
      const key = PreferencesKeys.videoResolution;
      final String expectedValue = defaultPreferences[PreferencesKeys.videoResolution];
      // Then
      expect(await prefService.getPrefOrDefault<String>(key), expectedValue);
    });

    test('throw error on bad Type - setPrefs', () async {
      // Given
      final prefService = PreferencesService();
      const key = PreferencesKeys.videoResolution;
      const List<String> expectedValue = [''];
      // Then
      try {
        await prefService.setPref<List<String>>(key, expectedValue);
        fail("test should fail on bad Typing");
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });

    test('throw error on bad Type - getPrefs', () async {
      // Given
      final prefService = PreferencesService();
      const key = PreferencesKeys.videoResolution;
      // Then
      try {
        await prefService.getPrefOrDefault<List<String>>(key);
        fail("test should fail on bad Typing");
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
