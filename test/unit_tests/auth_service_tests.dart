

import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/services/auth_service.dart' as auth;

void main() {
  group("authentication service test", () {
    late auth.AuthService authService;
    final Logger logger = Logger();
    setUp(() {
      logger.d("running set up");
      final firebaseAuth = MockFirebaseAuth();
      final googleSignIn = MockGoogleSignIn();

      authService = auth.AuthService.dependentOn(firebaseAuth, googleSignIn);
    });

    test("user is not signed in", () {
      expect(authService.isSignedIn(), false);
    });
    test("sign in with google", () {});
    test("sign in with email", () {});
    test("sign out", () {});
    test("sign up with email", () {});
  });
}