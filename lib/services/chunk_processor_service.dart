import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:logger/logger.dart';

import '../providers/auth_provider.dart';
import '../repositories/file_system_repo.dart';

class ChunkProcessorService {
  late FileSystemRepository fileSystemRepository;
  final Logger _logger = Logger();

  ChunkProcessorService({required this.fileSystemRepository});

  Future<void> processChunk(XFile videoChunk, int chunkNumber) async {
    Directory dir =
        await fileSystemRepository.stopRecording(videoChunk, chunkNumber);
    _FFmpeg(videoChunk, dir.path);
  }

  Future<void> _FFmpeg(XFile videoChunk, String outputDir) async {
    FlutterFFmpeg ffmpeg = FlutterFFmpeg();

    int intervalInSeconds = 5;

    int rc = await ffmpeg.execute(
        '-i $outputDir -vf fps=1/$intervalInSeconds ${outputDir}frame-%03d.jpg');

    if (rc == 0) {
      _logger.i('Frames extracted successfully');
    } else {
      _logger.e('Error extracting frames: $rc');
    }
  }
}
