import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/sensors_provider.dart';
import 'package:safety_eye_app/providers/permissions_provider.dart';
import '../repositories/file_system_repo.dart';
import 'auth_provider.dart';

class VideoRecordingProvider extends ChangeNotifier {
  CameraController? cameraController;
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

  get isRecording => cameraController?.value.isRecordingVideo ?? false;

  get isInitialized => cameraController?.value.isInitialized ?? false;

  Future<void> initializeCamera() async {
    cameraController = CameraController(permissions.cameras[0], ResolutionPreset.max);
    try{
      await cameraController?.initialize();
      _fileSystemRepository = FileSystemRepository(
          userEmail: authenticationProvider.currentUser?.uid ?? "");
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
    _logger.d("start recording: status ${cameraController?.value.isRecordingVideo}");
    if (!(cameraController?.value.isRecordingVideo ?? false)) {
      await cameraController?.startVideoRecording();
      _fileSystemRepository.startRecording();
      _logger.d("start recording: status ${cameraController?.value.isRecordingVideo}");
    }
  }

  Future<void> stopRecording() async {
    _logger.d("stopped recording: status ${cameraController?.value.isRecordingVideo}");
    if (cameraController?.value.isRecordingVideo ?? false) {
       cameraController?.stopVideoRecording().then((tempFile) {
        _logger.d("stopped recording: status ${cameraController?.value.isRecordingVideo}");
        return _fileSystemRepository.stopRecording(tempFile, 1);
      });

    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
