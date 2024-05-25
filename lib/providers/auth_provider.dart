import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../services/auth_service.dart';

class AuthenticationProvider extends ChangeNotifier {
  final AuthService _auth;
  final Logger _logger = Logger();
  User? _currentUser;
  bool isDev = false;

  User? get currentUser {
    return isDev ? MockUser() : _currentUser;
  }

  AuthenticationProvider(this._auth) {
    _auth.listenUserStream((user) {
      _logger.i('user changed: $user');
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _logger.i('Attepting to sign in with email: $email');
      _currentUser = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _logger.i('Signed in with email: $email');
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _logger.i('Attepting to sign up with email: $email');
      _currentUser = await _auth.signUpWithEmailAndPassword(email: email, password: password);
      _logger.i('Signed up with email: $email');
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _logger.i('Attepting to sign in with Google');
      _currentUser = await _auth.signInWithGoogle();
      _logger.i('Signed in with Google');
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  bool isSignedIn() {
    _logger.i('Checking if user is signed in');
    _currentUser = _auth.currentUser;
    notifyListeners();
    _logger.i('Checking if user is signed in: $_currentUser');
    return currentUser != null;
  }
}
