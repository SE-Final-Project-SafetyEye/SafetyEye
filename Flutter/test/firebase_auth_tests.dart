import 'package:app_tamplate/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  group('Firebase Authentication Tests', () {
    late FirebaseAuth auth;

    setUpAll(() async {
      // Initialize Firebase App for testing
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
      auth = FirebaseAuth.instance;
    });

    test('User Registration Test', () async {
      // Test User Credentials
      const String testEmail = 'test@example.com';
      const String testPassword = 'testPassword123';

      // Register a new user
      final UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Verify that the user is registered
      expect(userCredential.user, isNotNull);
    });

    test('User Login Test', () async {
      // Test User Credentials
      const String testEmail = 'test@example.com';
      const String testPassword = 'testPassword123';

      // Log in with the registered user
      final UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      // Verify that the user is logged in
      expect(userCredential.user, isNotNull);
    });

    test('User Logout Test', () async {
      // Log out the user
      await auth.signOut();

      // Verify that the user is signed out
      expect(auth.currentUser, isNull);
    });
  });
}
