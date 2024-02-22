import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  final Logger _log = Logger();

  User? get user => currentUser;

  AuthProvider() {
    _auth.authStateChanges().listen(_userAuthStateChange);
  }

  void _userAuthStateChange(user) {
    currentUser = user;
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    currentUser = userCredential.user;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentUser = null;
    notifyListeners();
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    currentUser = userCredential.user;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    currentUser = userCredential.user;
    _log.i('User signed in with Google');
    _log.i(currentUser?.email);
    notifyListeners();
  }

  Future<void> signOutGoogle() async {
    await GoogleSignIn().signOut();
    await signOut();
  }

}
