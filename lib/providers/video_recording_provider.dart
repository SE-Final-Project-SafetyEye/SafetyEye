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
  int chunkNumber = 1;
  late double recordMin;
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
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
    Timer.periodic(const Duration(seconds: 5), (Timer timer) async {
      _logger.i("Timer.periodic photo detection round");
      if (!cameraController!.value.isRecordingVideo) {
        await _captureAndDetectImage();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _captureAndDetectImage() async {
    try {

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
      const path = 'assets/object_labeler.tflite';
      final modelPath = await getAssetPath(path);
      final options =
          LocalLabelerOptions(modelPath: modelPath);

      final imageLabeler = ImageLabeler(options: options);

      final List<ImageLabel> labels =
          await imageLabeler.processImage(inputImage);


      // Log the detected labels
      for (ImageLabel label in labels) {
        final String text = label.label;
        final double confidence = label.confidence;
        _logger.i('Detected: $text with confidence: $confidence');
        if(vehicles.contains(text.toLowerCase()) && confidence > 0.80){
          startRecording(false);
        }
      }

      imageLabeler.close();
      file.delete();
    } catch (e) {
      _logger.e('Error capturing and detecting image: $e');
    } finally {
// Reset flag when capture is complete
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

  InputImage? _inputImageFromCameraImage(XFile imageFile) {
    try {
      final bytes = File(imageFile.path).readAsBytesSync();

      // Check if preview size is available
      if (cameraController?.value.previewSize == null) {
        throw Exception('Camera preview size is null');
      }

      // Get preview size and format
      final previewSize = cameraController!.value.previewSize!;
      final format = Platform.isAndroid
          ? InputImageFormat.nv21 // Use NV21 format for Android
          : InputImageFormat.bgra8888; // Use BGRA8888 format for iOS

      // Calculate bytes per row based on format
      final bytesPerRow = (format == InputImageFormat.nv21)
          ? (previewSize.width * 3 / 2).toInt() // NV21 has 1.5 bytes per pixel
          : previewSize.width.toInt() * 4; // BGRA8888 has 4 bytes per pixel

      // Determine rotation based on device orientation
      InputImageRotation? rotation;
      final sensorOrientation = cameraController?.description.sensorOrientation;
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation!);
      } else if (Platform.isAndroid) {
        var rotationCompensation =
            _orientations[cameraController!.value.deviceOrientation];
        if (rotationCompensation == null) return null;
        if (cameraController?.description.lensDirection ==
            CameraLensDirection.front) {
          // front-facing camera
          rotationCompensation =
              (sensorOrientation! + rotationCompensation) % 360;
        } else {
          // back-facing camera
          rotationCompensation =
              (sensorOrientation! - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
      if (rotation == null) return null;

      // Create InputImage instance
      return InputImage.fromBytes(
        bytes: Uint8List.fromList(bytes),
        metadata: InputImageMetadata(
          size:
              Size(previewSize.width.toDouble(), previewSize.height.toDouble()),
          format: format,
          bytesPerRow: bytesPerRow,
          rotation: rotation,
        ),
      );
    } catch (e) {
      _logger.e('Error creating InputImage: $e');
      return null;
    }
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
