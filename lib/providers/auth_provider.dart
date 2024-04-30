import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

import '../services/auth_service.dart';

class AuthenticationProvider extends ChangeNotifier{
  final AuthService _auth = AuthService();
  final Logger _logger = Logger();
  User? _currentUser;

  User? get currentUser{
    return _currentUser;
  }

  AuthenticationProvider(){
    _auth.listenUserStream((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async{

      try {
        _currentUser = await _auth.signInWithEmailAndPassword(email: email, password: password);
      } catch (error,stackTrace) {
        _logger.e(error.toString(), stackTrace: stackTrace);
      }
  }


  Future<void> signUpWithEmailAndPassword(String email, String password) async{
    try {
      _currentUser = await _auth.signUpWithEmailAndPassword(email: email, password: password);
    } catch (error,stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }
  bool isSignedIn(){
    return currentUser!= null;
  }
}