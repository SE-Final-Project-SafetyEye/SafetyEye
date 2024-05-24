import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_eye_app/providers/signatures_provider.dart';

import 'package:video_thumbnail/video_thumbnail.dart';

import '../services/BackendService.dart';
import '../repositories/file_system_repo.dart';
import 'auth_provider.dart';

class ChunksProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  List<String> chunksPaths = [];
  final List<String?> _thumbnails = [];
  final AuthenticationProvider authenticationProvider;
  final FileSystemRepository fileSystemRepository;
  final BackendService backendService;
  final SignaturesProvider signaturesProvider;

  ChunksProvider(
      {required this.authenticationProvider,
      required this.backendService,
      required this.fileSystemRepository,
      required this.signaturesProvider});

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

  handlePlayButtonPress(int videoIndex) {
    return chunksPaths[videoIndex];
  }

  Future<void> getChunk(String journeyId) async {
    final chunks = await backendService.getJourneyChunks(journeyId);
    chunksPaths = chunks;
  }

  Future<void> download(String journeyId, int chunkId) async {
    backendService.downloadChunk(
        journeyId, chunkId.toString()); //TODO: check if works
  }

  Future<bool> handleVerifiedSignatureButtonPress(int index) async {
    String message =
        await fileSystemRepository.getFileMassage(chunksPaths[index]);
    Signature? signature = await signaturesProvider.getSignature(message);
    if (signature != null) {
      return await signaturesProvider.verifySignature(message, signature);
    }
    return false;
  }
}
