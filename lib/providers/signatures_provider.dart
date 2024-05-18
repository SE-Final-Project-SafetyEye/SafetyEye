import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/services/signatures_service.dart';

class SignaturesProvider extends ChangeNotifier {
  final SignaturesService signaturesService;

  SignaturesProvider(
      AuthenticationProvider authProvider, this.signaturesService) {
    final user = authProvider.currentUser;
    if (user != null) {
      signaturesService.init();
    }
    listenToAuth(authProvider);
  }

  void listenToAuth(AuthenticationProvider authProvider) {
    authProvider.addListener(() {
      final user = authProvider.currentUser;
      if (user != null) {
        signaturesService.init();
      }
    });
  }

  Future<Signature> sign(String message) async =>
      signaturesService.signMessage(message);

  Future<bool> verifySignature(String message, Signature signature) async =>
      signaturesService.verifySignature(message, signature);
}
