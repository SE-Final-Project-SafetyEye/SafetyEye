import 'dart:async';

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
  bool recording = false;
  int chunkNumber = 1;
  double recordMin = 0.12;

  VideoRecordingProvider(
      {required this.permissions,
      required this.sensorsProvider,
      required this.authenticationProvider});

  get camera => cameraController;

  get isRecording =>
      recording; //cameraController?.value.isRecordingVideo ?? false;

  get isInitialized => cameraController?.value.isInitialized ?? false;

  Future<void> initializeCamera() async {
    cameraController =
        CameraController(permissions.cameras[0], ResolutionPreset.max);
    try {
      await cameraController?.initialize();
      _fileSystemRepository = FileSystemRepository(
          userEmail: authenticationProvider.currentUser?.uid ?? "nitayv");
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
    _logger.d(
        "start recording: status ${cameraController?.value.isRecordingVideo}");
    if (!(cameraController?.value.isRecordingVideo ?? false)) {
      recording = true;
      chunkNumber = 1;
      _fileSystemRepository.startRecording();
      sensorsProvider.startCollectMetadata();
      _logger.d(
          "start recording: status ${cameraController?.value.isRecordingVideo}");
      recordRecursively();
    }
  }

  void recordRecursively() async {
    _logger.i("recordRecursively, chunkNumber: $chunkNumber");
    if (recordMin > 0) {
      await cameraController?.startVideoRecording();

      await Future.delayed(
          Duration(milliseconds: (recordMin * 60 * 1000).toInt()));
      if (cameraController!.value.isRecordingVideo) {
        stopRecording(true);
      }
    }
  }

  void stopRecording(bool isRecordRecursively) {
    _logger.d(
        "stopped recording: status ${cameraController?.value.isRecordingVideo}");
    if (cameraController?.value.isRecordingVideo ?? false) {
      recording = isRecordRecursively;
      if (!isRecordRecursively) {
        sensorsProvider
            .stopCollectMetadata()
            .then((value) => _fileSystemRepository.saveDataToFile(value));
      }
      cameraController?.stopVideoRecording().then((tempFile) {
        _logger.d(
            "stopped recording: status ${cameraController?.value.isRecordingVideo}");
        _fileSystemRepository.stopRecording(tempFile, chunkNumber);
        chunkNumber++;
        if(isRecordRecursively){ recordRecursively();}
      });
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
