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
      const key = PreferencesKeys.privateKey;
      const String expectedValue = 'new_private_key';
      // When
      await prefService.setPref<String>(key, expectedValue);
      // Then
      expect(await prefService.getPrefOrDefault<String>(key), expectedValue);
    });

    test('validate default preference', () async {
      // Given
      final prefService = PreferencesService();
      const key = PreferencesKeys.privateKey;
      final String expectedValue = defaultPreferences[PreferencesKeys.privateKey];
      // Then
      expect(await prefService.getPrefOrDefault<String>(key), expectedValue);
    });

    test('throw error on bad Type - setPrefs', () async {
      // Given
      final prefService = PreferencesService();
      const key = PreferencesKeys.privateKey;
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
      const key = PreferencesKeys.privateKey;
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
