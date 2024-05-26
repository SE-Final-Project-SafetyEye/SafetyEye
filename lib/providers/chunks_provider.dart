import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'package:video_thumbnail/video_thumbnail.dart';

import '../services/BackendService.dart';
import '../repositories/file_system_repo.dart';
import '../views/components/videoPlayer/video_player.dart';
import 'auth_provider.dart';

class ChunksProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  List<String> chunksPaths = [];
  final List<String?> _thumbnails = [];
  final AuthenticationProvider authenticationProvider;
  final FileSystemRepository fileSystemRepository;
  final BackendService backendService;

  ChunksProvider({required this.authenticationProvider,required this.backendService,required this.fileSystemRepository});

  Future<void> initChunks(String path) async {
    chunksPaths = await fileSystemRepository.getChunksList(path);
    _logger.i("chunksPaths: ${chunksPaths.length}");

    for (String chunkPath in chunksPaths) {
      String? thumbnail = await _generateThumbnail(chunkPath);
      _thumbnails.add(thumbnail);
    }
  }

  Future<String?> _generateThumbnail(String videoPath) async {
    String? thumbnail;
    try {
      thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 100,
        quality: 25,
      );
      _logger.i("_generateThumbnail: Thumbnail generated for $videoPath");
    } catch (e) {
      _logger.e('Error generating thumbnail for $videoPath: $e');
      thumbnail = null; // Set thumbnail to null on error
    }
    return thumbnail;
  }

  generateThumbnailIsNotEmpty(int videoIndex) {
    _logger.i("generateThumbnailIsNotEmptyLEN: ${_thumbnails.length}");
    return _thumbnails[videoIndex]?.isNotEmpty;
  }

  getThumbnail(int videoIndex) {
    return fileSystemRepository.getThumbnailFile(_thumbnails[videoIndex]!);
  }

  String getName(int videoIndex) {
    return "";
  } //TODO: chunk's name

  Future<void> handleHighlightsButtonPress(int videoIndex) async {} //TODO:

  Future<void> handleCloudUploadButtonPress(int videoIndex) async {} //TODO:

  handlePlayButtonPress(context,int videoIndex) {
    String videoPath = chunksPaths[videoIndex]; // Assuming chunksPaths contains video paths
    // Perform actions to play the video, such as opening a video player
    _logger.i('Playing video: $videoPath');
    // Example code to open a video player (you'll need to replace this with your actual video player implementation)
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChewieVideoPlayer(srcs: [videoPath],)));
  }

  Future<void> getChunk(String journeyId) async{
    final chunks = await backendService.getJourneyChunks(journeyId);
    chunksPaths = chunks;
  }

  Future<void> download(String journeyId ,int chunkId) async {
    backendService.downloadChunk(journeyId, chunkId.toString()); //TODO: check if works
  }

}
