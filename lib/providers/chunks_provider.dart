import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_eye_app/providers/providers.dart';

import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/payloads/request/requests.dart';
import '../services/BackendService.dart';
import '../repositories/file_system_repo.dart';

class ChunksProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  List<String> chunksPaths = [];
  final List<String?> thumbnails = [];
  final AuthenticationProvider authenticationProvider;
  final SignaturesProvider signaturesProvider;
  final FileSystemRepository fileSystemRepository;
  final BackendService backendService;

  ChunksProvider(
      {required this.authenticationProvider,
      required this.backendService,
      required this.fileSystemRepository,
      required this.signaturesProvider});

  Future<List<String>> initChunks(String path) async {
    chunksPaths = await fileSystemRepository.getChunksList(path);
    _logger.i("chunksPaths: ${chunksPaths.length}");

    for (String chunkPath in chunksPaths) {
      String? thumbnail = await _generateThumbnail(chunkPath);
      thumbnails.add(thumbnail);
    }
    return chunksPaths;
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
    _logger.i("generateThumbnailIsNotEmptyLEN: ${thumbnails.length}");
    return thumbnails[videoIndex]?.isNotEmpty;
  }

  getThumbnail(int videoIndex) {
    return fileSystemRepository.getThumbnailFile(thumbnails[videoIndex]!);
  }

  Future<void> handleHighlightsButtonPress(int videoIndex) async {} //TODO:

  Future<void> handleCloudUploadButtonPress(int videoIndex) async {
    File video = fileSystemRepository.getChunkVideo(chunksPaths[videoIndex]);
    List<File> pics =
        fileSystemRepository.getChunkPics(chunksPaths[videoIndex]);
    File metaData =
        fileSystemRepository.getChunkMetadata(chunksPaths[videoIndex]);

    String videoSign =
        await signaturesProvider.getSignature(fileSystemRepository.getName(video.path));
    String metaDataSign =
        await signaturesProvider.getSignature(fileSystemRepository.getName(metaData.path));

    List<Future<String>> picSignFutures = pics
        .map(
            (pic) async => signaturesProvider.getSignature(fileSystemRepository.getName(pic.path)))
        .toList();
    List<String> picsSign = await Future.wait(picSignFutures);

    UploadChunkSignaturesRequest uploadChunkSignaturesRequest =
        UploadChunkSignaturesRequest(
      videoSig: videoSign,
      picturesSig: picsSign,
      metadataSig: metaDataSign,
    );

    backendService.uploadChunk(
        video, pics, metaData, uploadChunkSignaturesRequest, null);
  }

  Future<String> _convert(File file) async {
    try {
      List<int> bytes = await file.readAsBytes();
      String base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      return '';
    }
  }

  handlePlayButtonPress(context, int videoIndex) {
    return chunksPaths[videoIndex]; // Assuming chunksPaths contains video paths
  }

  Future<void> getChunk(String journeyId) async {
    final chunks = await backendService.getJourneyChunks(journeyId);
    chunksPaths = chunks;
  }

  Future<void> download(String journeyId, int chunkId) async {
    backendService.downloadChunk(
        journeyId, chunkId.toString()); //TODO: check if works
  }
}
