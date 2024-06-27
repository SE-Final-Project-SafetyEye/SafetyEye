import 'dart:async';

import 'package:async/async.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  late VideoRecordingProvider cameraProvider;
  late Future<CameraController> controllerFuture;
  final SpeechToText speech = SpeechToText();
  SpeechStatusListener? listener;
  final SpeechListenOptions speechListenOptions = SpeechListenOptions(partialResults: false, sampleRate: 44100);

  @override
  void initState() {
    super.initState();
    KeepScreenOn.turnOn();
    controllerFuture = widget.videoRecordingProvider.initializeCamera().then((_) => widget.videoRecordingProvider.cameraController!);
    cameraProvider = Provider.of<VideoRecordingProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      listener = ((status) => {if(status == 'notListening') _restartListening()});
      await _initializeSpeechRecognition();
    });
  }

  Future<void> _handleSpeechResult(SpeechRecognitionResult result) async {

    _logger.i("_handleSpeechResult: result = $result");
    _logger.i("Recognized words: ${result.recognizedWords}");

    var recognizedWords = result.recognizedWords.toLowerCase();
    var isStartEvent = recognizedWords.contains('start recording') ||
        recognizedWords.contains('start');
    var isStopEvent = recognizedWords.contains('stop recording') ||
        recognizedWords.contains('stop');
    var isHighlightEvent = recognizedWords.contains('highlight');

    if (isStartEvent) {
      _logger.i('Starting recording');
      if (!cameraProvider.isRecording) await cameraProvider.startRecording();
      _restartListening();
    } else if (isStopEvent) {
      _logger.i('Stopping recording');
      if (cameraProvider.isRecording) cameraProvider.stopRecording(false);
      _restartListening();
    } else if (isHighlightEvent) {
      _logger.i('Asked to highlight');
      await cameraProvider.highlight();
      _restartListening();
    }

  }

  Future<void> _initializeSpeechRecognition() async {
    try {
      bool available = await speech.initialize(onStatus: listener);
      if (available) {
        // TODO: totally disable app sounds -> below code does not mute the recording notifications
        // await FlutterVolumeController.updateShowSystemUI(false); // Hide system volume UI
        // await FlutterVolumeController.setMute(true, stream: AudioStream.alarm); // Set volume to 0 to silence feedback
        _logger.d("Initializing voice recognition...");
        // listenFor and pauseFor are strictly equal to 5 due to android system voice listen duration
        speech.listen( onResult: _handleSpeechResult, listenFor: const Duration(seconds: 5), pauseFor: const Duration(seconds: 5),listenOptions: speechListenOptions);
      }
      else {
        _logger.w("The user has denied the use of speech recognition.");
      }
    }catch (error, stackTrace) {
      _logger.e(error.toString(), stackTrace: stackTrace);
    }
  }

  void _restartListening() async {
    await speech.stop();
    // listenFor and pauseFor are strictly equal to 5 due to android system voice listen duration
    speech.listen( onResult: _handleSpeechResult, listenFor: const Duration(seconds: 5), pauseFor: const Duration(seconds: 5),listenOptions: speechListenOptions);
  }

  @override
  void dispose() {
    super.dispose();
    KeepScreenOn.turnOff();
    FlutterVolumeController.setMute(false,
        stream: AudioStream.alarm); // Restore volume
    speech.stop(); // Stop listening if the widget is disposed
    listener = null;
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
              // speech.stop();
              _restartListening();
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
