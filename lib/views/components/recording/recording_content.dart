import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

import '../../../providers/video_recording_provider.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final Logger _logger = Logger();
  bool isRecording = false;
  StreamSubscription<SpeechRecognitionEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeechRecognition(context);
    });
  }

  Future<void> _handleSpeechResult(SpeechRecognitionResult result) async {
    var camera = Provider.of<VideoRecordingProvider>(context, listen: false);
    if (result.recognizedWords
        .toLowerCase()
        .contains('start recording') /* && result.confidence > 0.85*/) {
      _logger.i('Starting recording');
      if (!camera.isRecording) await camera.startRecording();
    }
    // else if(result.recognizedWords.toLowerCase().contains('start recording') && result.confidence > 0.75) {
    //   // If the confidence is lower than 0.85, but higher then 0.75 ask for confirmation
    // }
    else if (result.recognizedWords
        .toLowerCase()
        .contains('stop recording') /*&& result.confidence > 0.85*/) {
      _logger.i('Stopping recording');
      if (camera.isRecording) camera.stopRecording(false);
    }
    // else if(result.recognizedWords.toLowerCase().contains('stop recording') && result.confidence > 0.75) {
    //   // If the confidence is lower than 0.85, but higher then 0.75 ask for confirmation
    // }
    else if (result.recognizedWords
        .toLowerCase()
        .contains('highlight') /*&& result.confidence > 0.85*/) {
      _logger.i('Asked to highlight');
      await camera.highlight();
    }
    //   else if(result.recognizedWords.toLowerCase().contains('highlight') && result.confidence > 0.75){
    //     // If the confidence is lower than 0.85, but higher then 0.75 ask for confirmation
    // }
  }

  Future<void> _initializeSpeechRecognition(BuildContext context) async {
    var speechProvider =
    Provider.of<SpeechToTextProvider>(context, listen: false);
    bool available = await speechProvider.initialize();
    if (available) {
      _startListening(speechProvider);
    } else {
      _logger.w("The user has denied the use of speech recognition.");
    }
  }

  void _startListening(SpeechToTextProvider speechProvider) async {
    await FlutterVolumeController.updateShowSystemUI(
        false); // Hide system volume UI
    await FlutterVolumeController.setMute(true,
        stream: AudioStream.alarm); // Set volume to 0 to silence feedback

    speechProvider.listen(
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 10),
      partialResults: false,
      onDevice: false,
      listenMode: ListenMode.confirmation,
    );

    _subscription = speechProvider.stream.listen((event) async {
      if (event.eventType == SpeechRecognitionEventType.finalRecognitionEvent) {
        var result = event.recognitionResult!;
        _logger.i("Final result: ${result.recognizedWords}");
        await _handleSpeechResult(result);
        _startListening(speechProvider); // Restart listening
      } else if (event.eventType == SpeechRecognitionEventType.errorEvent) {
        // _logger.e("Error: ${event.error?.errorMsg}");
        _startListening(speechProvider); // Restart listening on error
      }
    });
  }


  @override
  void dispose() {
    KeepScreenOn.turnOff();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeechRecognition(context);
    });
    var speechProvider = Provider.of<SpeechToTextProvider>(context, listen: false);
    speechProvider.stop(); // Stop listening if the widget is disposed
    _subscription?.cancel();
    FlutterVolumeController.setMute(false, stream: AudioStream.alarm); // Restore volume
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<VideoRecordingProvider>(context, listen: true);
    if (cameraProvider.isInitialized) {
      return buildCamaraPreviewContent(cameraProvider);
    } else {
      return FutureBuilder(
          future: cameraProvider.initializeCamera(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.connectionState == ConnectionState.done) {
              return buildCamaraPreviewContent(cameraProvider);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          });
    }
  }

  Column buildCamaraPreviewContent(VideoRecordingProvider cameraProvider) {
    return Column(children: [
      Expanded(
        child: Center(child: CameraPreview(cameraProvider.cameraController!)),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(15, 15, 15, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 15),
            SizedBox(width: 15),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(
              width: 15,
            ),
            ElevatedButton.icon(
              label: Text(
                cameraProvider.isRecording ? 'Stop' : 'Record',
              ),
              onPressed: () async {
                _logger.i(
                    "Recording button pressed. is recording: ${cameraProvider.isRecording}, isRecordingState: $isRecording");
                if (cameraProvider.isRecording) {
                  _logger.i("Stopping recording...");
                  cameraProvider.stopRecording(false);
                  setIsRecording(false);
                  _logger.i("Recording stopped.");
                } else {
                  _logger.i("Starting recording...");
                  await cameraProvider.startRecording();
                  _logger.i("Recording started.");
                  setIsRecording(true);
                }
                _logger.i(
                    "Recording button pressed. is recording: ${cameraProvider.isRecording}, isRecordingState: $isRecording");
              },
              icon: Icon(
                cameraProvider.isRecording ? Icons.stop : Icons.circle,
              ),
            ),
          ],
        ),
      )
    ]);
  }

  void setIsRecording(bool isRecording) {
    setState(() {
      this.isRecording = isRecording;
    });
  }
}
