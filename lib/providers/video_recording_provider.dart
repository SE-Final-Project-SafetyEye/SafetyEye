import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/sensors_provider.dart';
import 'package:safety_eye_app/providers/permissions_provider.dart';
import '../repositories/file_system_repo.dart';
import 'auth_provider.dart';

class VideoRecordingProvider extends ChangeNotifier {
  late CameraController cameraController;
  final Logger _logger = Logger();
  late SensorsProvider sensorsProvider;
  late PermissionsProvider permissions;
  late AuthenticationProvider authenticationProvider;
  late FileSystemRepository _fileSystemRepository;

  VideoRecordingProvider(
      {required this.permissions,
      required this.sensorsProvider,
      required this.authenticationProvider});

  get camera  => cameraController;

  get isRecording => cameraController.value.isRecordingVideo;

  get isInitialized => cameraController.value.isInitialized;

  Future<void> initializeCamera() async {
    cameraController = CameraController(permissions.cameras[0], ResolutionPreset.max);
    try{
      await cameraController.initialize();
      _fileSystemRepository = FileSystemRepository(
          userEmail: authenticationProvider.currentUser?.uid ?? "nitayv");
    }
    catch (e){
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            _logger.e('User denied camera access');
            break;
          default:
            _logger.e('Unknown error');
            break;
        }
      }
    }
  }

  Future<void> startRecording() async {
    _logger.d("start recording: status ${cameraController.value.isRecordingVideo}");
    if (!cameraController.value.isRecordingVideo) {
      await cameraController.startVideoRecording();
      _fileSystemRepository.startRecording();
      _logger.d("start recording: status ${cameraController.value.isRecordingVideo}");
    }
  }

  Future<void> stopRecording() async {
    _logger.d("stopped recording: status ${cameraController.value.isRecordingVideo}");
    if (cameraController.value.isRecordingVideo) {
       cameraController.stopVideoRecording().then((tempFile) {
        _logger.d("stopped recording: status ${cameraController.value.isRecordingVideo}");
        return _fileSystemRepository.stopRecording(tempFile, 1);
      });

    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
