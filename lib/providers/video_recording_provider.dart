import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
  bool photoDetection = false;
  int chunkNumber = 1;
  late double recordMin;
  final List<String> vehicles = [
    'car',
    'truck',
    'bus',
    'motorcycle',
    'bicycle',
    'van',
    'suv',
    'rv',
    'train',
    'ambulance',
    'fire truck',
    'police car',
    'taxi',
    'construction vehicle',
    'garbage truck',
  ];
  late ImageLabeler _imageLabeler;
  late LocalLabelerOptions labelerOptions;

  VideoRecordingProvider({
    required this.permissions,
    required this.sensorsProvider,
    required this.authenticationProvider,
    required this.settingsProvider,
    required this.fileSystemRepository,
    required this.chunkProcessorService,
  });

  bool get isRecording => recording;

  bool get isInitialized => cameraController?.value.isInitialized ?? false;

  Future<void> initializeCamera() async {
    bool hasPermission = await permissions.checkAndRequestCameraPermissions();
    if (!hasPermission) {
      throw Future.error("Camera permission denied");
    }
    if (isInitialized) {
      return;
    }
    const path = 'assets/object_labeler.tflite';
    final modelPath = await getAssetPath(path);
    labelerOptions = LocalLabelerOptions(modelPath: modelPath);
    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0], // Use first available camera
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    recordMin = settingsProvider.settingsState.chunkDuration / 60;
    try {
      await cameraController?.initialize();
      _startImageCaptureTimer();
    } catch (e) {
      if (e is CameraException) {
        _handleCameraException(e);
      } else {
        _logger.e('Error initializing camera: $e');
      }
    }
  }

  void _startImageCaptureTimer() {
    Timer.periodic(const Duration(seconds: 20), (Timer timer) async {
      _logger.i("Timer.periodic photo detection round");
      if (!cameraController!.value.isRecordingVideo) {
        await _captureAndDetectImage();
        if (cameraController!.value.isRecordingVideo) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _captureAndDetectImage() async {
    try {
      if (!photoDetection) {
        photoDetection = true;

        // Capture the image
        final XFile? imageFile = await cameraController?.takePicture();

        if (imageFile == null) return;

        // Ensure the file exists
        final file = File(imageFile.path);
        if (!await file.exists() || await file.length() == 0) {
          throw Exception('The asset does not exist or has empty data.');
        }

        // Process the image
        final inputImage = InputImage.fromFile(file);

        _imageLabeler = ImageLabeler(options: labelerOptions);
        // Label detection
        final List<ImageLabel> labels = await _imageLabeler.processImage(inputImage);

        // Log the detected labels
        for (ImageLabel label in labels) {
          final String text = label.label;
          final double confidence = label.confidence;
          _logger.i('Detected: $text with confidence: $confidence');

          // Check if detected label matches any vehicle and confidence is above 0.80
          for (String vehicle in vehicles) {
            if (text.toLowerCase().contains(vehicle)) {
              startRecording(false);
              return;
            }
          }
        }
        _imageLabeler.close();
        file.delete();
      }
    } catch (e) {
      _logger.e('Error capturing and detecting image: $e');
    } finally {
      photoDetection = false;
    }
  }


  Future<String> getAssetPath(String asset) async {
    final path = await getLocalPath(asset);
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  Future<String> getLocalPath(String path) async {
    return '${(await getApplicationSupportDirectory()).path}/$path';
  }

  Future<void> startRecording(bool isHighlight) async {
    _logger.d("Start recording: ${cameraController?.value.isRecordingVideo}");
    if (!(cameraController?.value.isRecordingVideo ?? false)) {
      recording = true;
      notifyListeners();
      chunkNumber = 1;
      fileSystemRepository.startRecording();
      await _recordRecursively(isHighlight);
    }
  }

  Future<void> _recordRecursively(bool isHighlight) async {
    _logger.i("Record recursively, chunkNumber: $chunkNumber");
    if (recordMin > 0) {
      await cameraController?.startVideoRecording();
      sensorsProvider.startCollectMetadata(isHighlight);
      await Future.delayed(
          Duration(milliseconds: (recordMin * 60 * 1000).toInt()));
      if (cameraController!.value.isRecordingVideo) {
        await stopRecording(true);
      }
    }
  }

  Future<void> stopRecording(bool isRecordRecursively) async {
    _logger.d("Stop recording: ${cameraController?.value.isRecordingVideo}");
    if (cameraController?.value.isRecordingVideo ?? false) {
      recording = isRecordRecursively;
      notifyListeners();
      String jsonFile = await sensorsProvider.stopCollectMetadata();
      cameraController?.stopVideoRecording().then((tempFile) async {
        _logger.i("Start chunk processing");
        chunkProcessorService.processChunk(tempFile, chunkNumber, jsonFile);
        chunkNumber++;
        if (isRecordRecursively) {
          await _recordRecursively(false);
        }
      });
    }
    _startImageCaptureTimer();
  }

  Future<void> highlight() async {
    _logger.d(
        "Highlight - Recording status: ${cameraController?.value.isRecordingVideo}");
    if (!(cameraController?.value.isRecordingVideo ?? false)) {
      await startRecording(true);
      _logger.d("Start recording: ${cameraController?.value.isRecordingVideo}");
      _logger.d("Start highlight: true");
    } else {
      sensorsProvider.setIsHighlight(true);
      _logger.d("Start highlight: true");
    }
  }

  void _handleCameraException(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        _logger.e('User denied camera access');
        break;
      default:
        _logger.e('Unknown camera error: ${e.code}');
        break;
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
