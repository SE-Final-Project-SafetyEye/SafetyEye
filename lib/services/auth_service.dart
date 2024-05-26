import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthService {
  FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  final Logger _logger = Logger();

  AuthService() {
    _auth = FirebaseAuth.instance;
  }



  @visibleForTesting
  AuthService.dependentOn(this._auth, this._googleSignIn);

  get currentUser => _auth.authStateChanges();

  void listenUserStream(void Function(User? user) callback) {
    _auth.authStateChanges().listen(callback);
  }

  Future<User?> signInWithEmailAndPassword({required String email, required String password}) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<User?> signUpWithEmailAndPassword({required String email, required String password}) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    UserCredential userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }

  bool isSignedIn() {
    return _auth.currentUser != null;
  }
}
