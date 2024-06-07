import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/providers.dart';
import 'package:uuid/uuid.dart';
import '../repositories/file_system_repo.dart';
import 'package:safety_eye_app/services/object_detection_service.dart';

class ChunkProcessorService {
  final FileSystemRepository fileSystemRepository;
  final SignaturesProvider signaturesProvider;
  final Logger _logger = Logger();
  var uuid = const Uuid();

  ChunkProcessorService({
    required this.fileSystemRepository,
    required this.signaturesProvider,
  });

  Future<void> processChunk(
      XFile videoChunk, int chunkNumber, String jsonMetaData) async {
    try {
      Uint8List videoBytes = await videoChunk.readAsBytes();
      Directory dir =
          await fileSystemRepository.stopRecording(videoChunk, chunkNumber);
      ModelObjectDetectionSingleton().addWork(dir.path);
      print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
      print('******************************************');
      print('##########################################');
      print(ModelObjectDetectionSingleton().numberOfIsolateUses);
      print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^');
      print('******************************************');
      print('##########################################');

      File jsonFile = await fileSystemRepository.saveDataToFile(jsonMetaData, chunkNumber);
      XFile jsonXFile = XFile(jsonFile.path);
      Uint8List jsonBytes = await jsonXFile.readAsBytes();
      await extractFrames(dir);
      await signaturesProvider.sign(jsonXFile.name, base64Encode(jsonBytes));
      XFile xFile = XFile(dir.path);
      await signaturesProvider.sign(xFile.name, base64Encode(videoBytes));
    } catch (e) {
      _logger.e('Error processing chunk: $e');
    }
  }

  Future<void> extractFrames(Directory outputDir) async {
    try {
      FlutterFFmpeg ffmpeg = FlutterFFmpeg();
      var uuidG = const Uuid().v4();
      _logger.i("outputDir: ${outputDir.path}");
      String chunknumber = XFile(outputDir.parent.path).name;

      String journeyId = XFile(outputDir.parent.parent.path).name;
      _logger.i("journeyId: ${journeyId}");
      int rc = await ffmpeg.execute(
        '-i ${outputDir.path} -vf fps=1/5 "${outputDir.parent.path}/${journeyId}_chunknumber-${chunknumber}_${uuidG}_pic-%03d.jpg"',
      );

      if (rc == 0) {
        _logger.i('Frames extracted successfully: ${outputDir.path}');
        await signVideoFrames(outputDir.path);
      } else {
        _logger.e('Error extracting frames: $rc');
      }
    } catch (e) {
      _logger.e('Exception during frame extraction: $e');
    }
  }



  Future<void> signVideoFrames(String outputDir) async {
    File file = File(outputDir);
    String directoryPath = file.parent.path;
    Directory directory = Directory(directoryPath);
    List<File> frames = [];

    if (!directory.existsSync()) {
      return;
    }

    List<FileSystemEntity> files = directory.listSync(recursive: true);

    for (FileSystemEntity entity in files) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        frames.add(entity);
      }
    }
    for (var entity in frames) {
      XFile frameFile = XFile(entity.path);
      Uint8List frameBytes = await frameFile.readAsBytes();
      await signaturesProvider.sign(frameFile.name, base64Encode(frameBytes));
    }
  }

  String _extractUuidFromFileName(String fileName) {
    List<String> parts = fileName.split('_');

    if (parts.length > 1) {
      String uuidPart = parts[1];
      return uuidPart.split('.').first; // Remove the "." extension if present
    } else {
      return '';
    }
  }
}
