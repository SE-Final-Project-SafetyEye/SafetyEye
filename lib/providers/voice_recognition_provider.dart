import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:logger/logger.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechProvider extends ChangeNotifier {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;
  final Logger _logger = Logger();

  SpeechProvider() {
    _speech = stt.SpeechToText();
  }

  bool get isListening => _isListening;
  String get text => _text;
  double get confidence => _confidence;

  void listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => _logger.i('onStatus: $val'),
        onError: (val) => _logger.e('onError: $val'),
      );
      if (available) {
        _isListening = true;
        _speech.listen(
          onResult: (val) {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
            notifyListeners();
          },
        );
      }
    } else {
      _isListening = false;
      _speech.stop();
      notifyListeners();
    }
  }
}
