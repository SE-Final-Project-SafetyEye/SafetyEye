import 'dart:io';

import 'package:logger/logger.dart';
import 'package:video_compress/video_compress.dart';

class CompressionService {
  final Logger _logger = Logger();

  Future<File> compressVideo(String videoPath,
      {VideoQuality quality = VideoQuality.LowQuality, bool deleteOrigin = false}) async {

    MediaInfo? compressedFile = await VideoCompress.compressVideo(
      videoPath,
      quality: quality,
      deleteOrigin: deleteOrigin,
      includeAudio: false,
    );

    if (compressedFile == null) {
      throw Exception("Could not compress video");
    }
    if (compressedFile.file == null) {
      throw Exception("Compressed file was not created");
    } else {
      _logger.i("Compressed file created: ${compressedFile.file!.path}");
      await compressedFile.file!.copy(videoPath);
      return File(videoPath);
    }
  }
}
