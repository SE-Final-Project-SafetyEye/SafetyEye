import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/sensors_provider.dart';
import 'package:safety_eye_app/providers/permissions_provider.dart';
import 'package:safety_eye_app/providers/settings_provider.dart';
import '../repositories/file_system_repo.dart';
import '../services/chunk_processor_service.dart';
import 'auth_provider.dart';

class VideoRecordingProvider extends ChangeNotifier {
  CameraController? cameraController;
  final Logger _logger = Logger();
  late SensorsProvider sensorsProvider;
  late PermissionsProvider permissions;
  late AuthenticationProvider authenticationProvider;
  late SettingsProvider settingsProvider;
  late FileSystemRepository fileSystemRepository;
  late ChunkProcessorService chunkProcessorService;
  bool recording = false;
  int chunkNumber = 1;
  late double recordMin;

  VideoRecordingProvider(
      {required this.permissions,
      required this.sensorsProvider,
      required this.authenticationProvider,
      required this.settingsProvider,
      required this.fileSystemRepository,
      required this.chunkProcessorService});

  get camera => cameraController;

  get isRecording => recording; //cameraController?.value.isRecordingVideo ?? false;

  get isInitialized => cameraController?.value.isInitialized ?? false;

  Future<void> initializeCamera() async {
    bool hasPermission = await permissions.checkAndRequestCameraPermissions();
    if (!hasPermission) {
      throw Future.error("this is an error");
    }
    if (isInitialized) {
      return;
    }
    cameraController = CameraController(permissions.cameras[0], ResolutionPreset.high, enableAudio: false);
    recordMin = 0.15; //settingsProvider.settingsState.chunkDuration; //TODO: delete the integer
    try {
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
      recording = true;
      notifyListeners();
      chunkNumber = 1;
      fileSystemRepository.startRecording();
      _logger.d("2 start recording: status ${cameraController?.value.isRecordingVideo}");
      await recordRecursively();
    }
  }

  Future<void> recordRecursively() async {
    _logger.i("1 recordRecursively, chunkNumber: $chunkNumber");
    if (recordMin > 0) {
      await cameraController?.startVideoRecording();
      sensorsProvider.startCollectMetadata();
      _logger.d("2 start recording: status ${cameraController?.value.isRecordingVideo}");
      await Future.delayed(Duration(milliseconds: (recordMin * 60 * 1000).toInt()));
      if (cameraController!.value.isRecordingVideo) {
        stopRecording(true);
      }
    }
  }

  Future<void> stopRecording(bool isRecordRecursively) async {
    _logger.d("1 stopped recording: status ${cameraController?.value.isRecordingVideo}");
    if (cameraController?.value.isRecordingVideo ?? false) {
      recording = isRecordRecursively;
      notifyListeners();
      String jsonFile = await sensorsProvider.stopCollectMetadata();
      cameraController?.stopVideoRecording().then((tempFile) async {
        _logger.d("stopped recording: status ${cameraController?.value.isRecordingVideo}");
        _logger.i("Start chunkProcessorService");
        _logger.i("2 stopped recording: status ${cameraController?.value.isRecordingVideo}");
        chunkProcessorService.processChunk(tempFile, chunkNumber,jsonFile);
        _logger.i("stop chunkProcessorService");
        chunkNumber++;
        if (isRecordRecursively) {
          await recordRecursively();
        }
      });
    }
  }

  // TODO fill this method
  Future<void> highlight() async {
    _logger.d("1 highlight - status recording ${cameraController?.value.isRecordingVideo}");
    if (!(cameraController?.value.isRecordingVideo ?? false)) {
      await startRecording();
      // add highlight flag
      _logger.d("2 start recording: status ${cameraController?.value.isRecordingVideo}");
      _logger.d("3 start highlight: status true");
    } else if (cameraController?.value.isRecordingVideo ?? false) {
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
