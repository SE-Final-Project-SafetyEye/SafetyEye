import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/services/signatures_service.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

class SignaturesProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final SignaturesService signaturesService;

  SignaturesProvider(AuthenticationProvider authProvider, SpeechToTextProvider speechToTextProvider, this.signaturesService) {
    final user = authProvider.currentUser;
    if (user != null) {
      signaturesService.init(authProvider);
    }
    listenToAuth(authProvider);
    listenToSpeech(speechToTextProvider);
  }

  void listenToAuth(AuthenticationProvider authProvider) {
    authProvider.addListener(() {
      final user = authProvider.currentUser;
      if (user != null) {
        signaturesService.init(authProvider);
      }
    });
  }

  void listenToSpeech(SpeechToTextProvider speechToTextProvider) {
    speechToTextProvider.addListener(() {
      _logger.i('listened to:  ${speechToTextProvider.lastResult?.recognizedWords}');
    });
  }
}
