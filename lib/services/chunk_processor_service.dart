import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/providers/providers.dart';
import '../repositories/file_system_repo.dart';

class ChunkProcessorService {
  final FileSystemRepository fileSystemRepository;
  final SignaturesProvider signaturesProvider;
  final Logger _logger = Logger();

  ChunkProcessorService({
    required this.fileSystemRepository,
    required this.signaturesProvider,
  });

  Future<void> processChunk(XFile videoChunk, int chunkNumber) async {
    try {
      Uint8List videoBytes = await videoChunk.readAsBytes();

      Directory dir =
          await fileSystemRepository.stopRecording(videoChunk, chunkNumber);
      await extractFrames(dir.path);
      await signaturesProvider.sign(base64Encode(videoBytes));
    } catch (e) {
      _logger.e('Error processing chunk: $e');
    }
  }

  Future<void> extractFrames(String outputDir) async {
    try {
      FlutterFFmpeg ffmpeg = FlutterFFmpeg();

      int intervalInSeconds = 5;

      int rc = await ffmpeg.execute(
          '-i $outputDir -vf fps=1/$intervalInSeconds ${outputDir}frame-%03d.jpg');

      if (rc == 0) {
        _logger.i('Frames extracted successfully: $outputDir');
        await signVideoFrames(outputDir);
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
    Directory outputDirectory = Directory(directoryPath);
    List<FileSystemEntity> frames = [];
    List<FileSystemEntity> files = outputDirectory.listSync();
    for (FileSystemEntity file in files) {
      FileStat fileStat = file.statSync();
      if (fileStat.type == FileSystemEntityType.file) {
        if (file.path.endsWith('.jpg')) {
          frames.add(file);
        }
      }
    }

    for (var entity in frames) {
      File frameFile = File(entity.path);
      Uint8List frameBytes = await frameFile.readAsBytes();
      await signaturesProvider.sign(base64Encode(frameBytes));
    }
  }
}
