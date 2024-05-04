import 'package:flutter/cupertino.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/services/signatures_service.dart';

class SignaturesProvider extends ChangeNotifier {
  final SignaturesService _signaturesService = SignaturesService();

  SignaturesProvider(AuthenticationProvider authProvider) {
    final user = authProvider.currentUser;
    if (user != null) {
      _signaturesService.init(user);
    }
    listenToAuth(authProvider);
  }

  void listenToAuth(AuthenticationProvider authProvider) {
    authProvider.addListener(() {
      final user = authProvider.currentUser;
      if (user != null) {
        _signaturesService.init(user);
      }
    });
  }
}
