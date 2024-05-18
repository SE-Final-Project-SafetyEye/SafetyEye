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
  late FileSystemRepository fileSystemRepository;

  VideoRecordingProvider(
      {required this.permissions,
      required this.sensorsProvider,
      required this.authenticationProvider,
      required this.fileSystemRepository});

  get camera => cameraController;

  get isRecording => cameraController?.value.isRecordingVideo ?? false;

  get isInitialized => cameraController?.value.isInitialized ?? false;

  Future<void> initializeCamera() async {
    cameraController = CameraController(permissions.cameras[0], ResolutionPreset.max, enableAudio: false);
    try{
      await cameraController?.initialize();
    } catch (e) {
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
    _logger.d("1 start recording: status ${cameraController?.value.isRecordingVideo}");
    if (!(cameraController?.value.isRecordingVideo ?? false)) {
      await cameraController?.startVideoRecording();
      fileSystemRepository.startRecording();
      _logger.d("2 start recording: status ${cameraController?.value.isRecordingVideo}");
    }
  }

  Future<void> stopRecording() async {
    _logger.d("1 stopped recording: status ${cameraController?.value.isRecordingVideo}");
    if (cameraController?.value.isRecordingVideo ?? false) {
       cameraController?.stopVideoRecording().then((tempFile) {
        _logger.d("2 stopped recording: status ${cameraController?.value.isRecordingVideo}");
        return fileSystemRepository.stopRecording(tempFile, 1);
      });
    }
  }

  // TODO fill this method
  Future<void> highlight() async {
    _logger.d("1 highlight - status recording ${cameraController?.value.isRecordingVideo}");
    if (!(cameraController?.value.isRecordingVideo ?? false)) {
      await cameraController?.startVideoRecording();
      fileSystemRepository.startRecording();
      // add highlight flag
      _logger.d("2 start recording: status ${cameraController?.value.isRecordingVideo}");
      _logger.d("3 start highlight: status true");
    }
    else if (cameraController?.value.isRecordingVideo ?? false) {
      // validate highlight flag
      _logger.d("2 start highlight: status ?");
      // start another highlight chunk if possible
      _logger.d("3 start highlight: status true");
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
