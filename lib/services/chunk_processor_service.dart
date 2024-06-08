import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:cryptography/cryptography.dart';
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

  Future<void> processChunk(XFile videoChunk, int chunkNumber, String jsonMetaData) async {
    try {
      Uint8List videoBytes = await videoChunk.readAsBytes();
      Directory dir = await fileSystemRepository.stopRecording(videoChunk, chunkNumber);




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

    if (!directory.existsSync()) {
      return;
    }

    List<FileSystemEntity> frames = await directory
        .list(recursive: true)
        .where((entity) => entity is File && entity.path.endsWith('.jpg'))
        .toList();

    List<Future<Signature>> futures = frames.map((frame) {
      final xFile = XFile(frame.path);
      return xFile
          .readAsBytes()
          .then((bytes) => signaturesProvider.sign(xFile.name, base64Encode(bytes)))
          .then((signature) {
        _logger.i("created signature for ${xFile.name}: $signature");
        return signature;
      });
    }).toList();

    await Future.wait(futures);
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
