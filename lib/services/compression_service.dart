import 'package:video_compress/video_compress.dart';

class CompressionService {
  Future<MediaInfo?> compressVideo(String videoPath,
      {VideoQuality quality = VideoQuality.LowQuality}) {
    return VideoCompress.compressVideo(
      videoPath,
      quality: quality,
      deleteOrigin: false,
    );
  }
}
