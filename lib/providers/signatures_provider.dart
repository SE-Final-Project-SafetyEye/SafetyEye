import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

  Future<Signature> sign(String id, String message, {bool saveToDb = true}) async {
    return signaturesService.signMessage(id,message, saveToDb);
  }

  Future<bool> verifySignature(List<int> message, Uint8List sigBytes) async {
    SimpleKeyPair keyPair = await signaturesService.getKeys();
    final publicKey = await keyPair.extractPublicKey();
    final signature = Signature(sigBytes, publicKey: publicKey);

    return await signaturesService.verifySignature(message, signature);
  }

  Future<String> getSignature(String id) async {
    return signaturesService.getSignature(id);
  }
}