import 'package:video_compress/video_compress.dart';

class CompressionService {
  Future<MediaInfo?> compressVideo(String videoPath,
      {VideoQuality quality = VideoQuality.LowQuality, bool deleteOrigin = false}) {
    return VideoCompress.compressVideo(
      videoPath,
      quality: quality,
      deleteOrigin: deleteOrigin,
      includeAudio: false,
    );
  }
}
