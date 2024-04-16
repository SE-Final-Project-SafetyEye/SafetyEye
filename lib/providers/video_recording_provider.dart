import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

class VideoRecordingProvider extends ChangeNotifier {
  late List<CameraDescription> cameras;
  late CameraController _cameraController;
  bool _isRecording = false;

  VideoRecordingProvider({required this.cameras});

  CameraController get cameraController => _cameraController;

  bool get isRecording => _isRecording;

  get isInitialized => cameraController.value.isInitialized;

  Future<void> initializeCamera() async {
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _cameraController.initialize();
    notifyListeners();
  }

  void startRecording() async {
    if (!_isRecording) {
      await _cameraController.startVideoRecording();
      _isRecording = true;
      notifyListeners();
    }
  }

  void stopRecording() async {
    if (_isRecording) {
      await _cameraController.stopVideoRecording();
      _isRecording = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}