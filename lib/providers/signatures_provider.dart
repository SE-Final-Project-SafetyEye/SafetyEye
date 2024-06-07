import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
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

  Future<Signature> sign(String id, String message) async {
    return signaturesService.signMessage(id,message);
  }

  Future<bool> verifySignature(String message, Signature signature) async =>
      signaturesService.verifySignature(message, signature);

  Future<bool> verifySignatureUint8List(Uint8List message, Signature signature) async =>
      signaturesService.verifySignatureUint8List(message, signature);

  Future<String> getSignature(String id) async {
    return signaturesService.getSignature(id);
  }

  Future<PublicKey> getPublicKey() async {
    return (await signaturesService.getKeys()).extractPublicKey();
  }
}
