
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  void listenUserStream(void Function(User? user) callback) {
    _auth.authStateChanges().listen(callback);
  }

  Future<User?> signInWithEmailAndPassword({ required String email, required String password}) async {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
  }


}