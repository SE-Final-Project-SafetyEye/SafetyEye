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
  final VideoRecordingProvider videoRecordingProvider;

  const RecordingPage(this.videoRecordingProvider,{super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final Logger _logger = Logger();
  bool isRecording = false;
  StreamSubscription<SpeechRecognitionEvent>? _subscription;
  late SpeechToTextProvider speechProvider;
  late VideoRecordingProvider cameraProvider;
  late Future<CameraController> controllerFuture;

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();
    controllerFuture = widget.videoRecordingProvider.initializeCamera().then((_) => widget.videoRecordingProvider.cameraController!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeechRecognition(context);

    });
  }

  Future<void> _handleSpeechResult(SpeechRecognitionResult result) async {
    cameraProvider =
        Provider.of<VideoRecordingProvider>(context, listen: false);
    var recognizedWords = result.recognizedWords.toLowerCase();
    var isStartEvent = recognizedWords.contains('start recording') ||
        recognizedWords.contains('start') ||
        recognizedWords.contains('record');
    var isStopEvent = recognizedWords.contains('stop recording') ||
        recognizedWords.contains('stop');
    var isHighlightEvent = recognizedWords.contains('highlight');

    if (isStartEvent) {
      _logger.i('Starting recording');
      if (!cameraProvider.isRecording) await cameraProvider.startRecording();
    } else if (isStopEvent) {
      _logger.i('Stopping recording');
      if (cameraProvider.isRecording) cameraProvider.stopRecording(false);
    } else if (isHighlightEvent) {
      _logger.i('Asked to highlight');
      await cameraProvider.highlight();
    }
  }

  Future<void> _initializeSpeechRecognition(BuildContext context) async {
    speechProvider = Provider.of<SpeechToTextProvider>(context, listen: false);
    bool available = await speechProvider.initialize();
    if (available) {
      await _subscribeToVoiceRecognition(speechProvider);
      await _startListening(speechProvider);
    } else {
      _logger.w("The user has denied the use of speech recognition.");
    }
  }

  Future<void> _subscribeToVoiceRecognition(
      SpeechToTextProvider speechProvider) async {
    await FlutterVolumeController.updateShowSystemUI(
        false); // Hide system volume UI
    await FlutterVolumeController.setMute(true,
        stream: AudioStream.alarm); // Set volume to 0 to silence feedback

    _logger.d("Subscribing to voice recognition...");

    _subscription = speechProvider.stream.listen((event) async {
      if (event.eventType == SpeechRecognitionEventType.finalRecognitionEvent) {
        var result = event.recognitionResult!;
        _logger.i("Final result: ${result.recognizedWords}");
        await _handleSpeechResult(result);
        await _startListening(speechProvider); // Restart listening
      } else if (event.eventType == SpeechRecognitionEventType.errorEvent) {
        // _logger.e("Error: ${event.error?.errorMsg}");
        // Future.delayed(const Duration(seconds: 1));
        await _startListening(speechProvider); // Restart listening on error
      }
    });
  }

  Future<void> _startListening(SpeechToTextProvider speechProvider) async {
    speechProvider.listen(
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 10),
      partialResults: false,
      onDevice: false,
      listenMode: ListenMode.confirmation,
    );
  }

  @override
  void dispose() {
    super.dispose();
    KeepScreenOn.turnOff();
    FlutterVolumeController.setMute(false,
        stream: AudioStream.alarm); // Restore volume
    WidgetsBinding.instance.addPostFrameCallback((_) {
      speechProvider.stop(); // Stop listening if the widget is disposed
      _subscription?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider =
        Provider.of<VideoRecordingProvider>(context, listen: true);
    if (cameraProvider.isInitialized) {
      return buildCamaraPreviewContent(cameraProvider);
    } else {
      return FutureBuilder(
          future: controllerFuture,
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

  Widget buildCamaraPreviewContent(VideoRecordingProvider cameraProvider) {
    return Stack(alignment: AlignmentDirectional.bottomEnd, children: [
      Center(child: CameraPreview(cameraProvider.cameraController!)),
      buildRecordButton(cameraProvider)
    ]);
  }

  Widget buildRecordButton(VideoRecordingProvider cameraProvider) {
    return Padding(
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
                _logger.i("Recording stopped.");
              } else {
                _logger.i("Starting recording...");
                await cameraProvider.startRecording();
                _logger.i("Recording started.");
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
    );
  }
}
