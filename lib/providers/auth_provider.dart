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
      _currentUser = await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _currentUser = await _auth.signUpWithEmailAndPassword(email: email, password: password);
      notifyListeners();
    } catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _currentUser = await _auth.signInWithGoogle();
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
    _currentUser = _auth.currentUser;
    notifyListeners();
    return currentUser != null;
  }
}
