import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_eye_app/exceptions.dart';
import 'package:safety_eye_app/providers/providers.dart';
import 'package:safety_eye_app/providers/upload_handler.dart';

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

  Future<void> handleCloudUploadButtonPress(int videoIndex, {ProgressCallback? progressCallback}) async {
    // got all the files
    var chunkPath = chunksPaths[videoIndex];
    File video = fileSystemRepository.getChunkVideo(chunkPath);
    _logger.i("fetch video file - path ${video.path}");
    List<File> pics = fileSystemRepository.getChunkPics(chunkPath);
    _logger.i("fetch pic files - length ${pics.length}");
    File metaData = fileSystemRepository.getChunkMetadata(chunkPath);
    _logger.i("fetch metadata file - path ${metaData.path}");

    // verify signatures
    _logger.i("********* Verifying Signatures ***********");
    UploadHandler uploadHandler = UploadHandler(signaturesProvider, fileSystemRepository, video, pics, metaData);
    bool verifyResult = await uploadHandler.verifySignatures();
    if (!verifyResult) {
      throw IntegrityException("Signature verification failed, video my be corrupt");
    } else {
      _logger.i("********* Signatures Verified ***********");
    }

    //run Ai model on video
    _logger.i("********* Running Object Detection Model ***********");
    await uploadHandler.runObjectDetectionModel();
    _logger.i("********* Object Detection Model Completed - merging metadata ***********");
    File mergedMetadataFile = await uploadHandler.mergeMetadata();
    //sign metadata
    String metadataSig = await uploadHandler.resignFile(mergedMetadataFile);

    //compress video and sign
    _logger.i("********* Compressing Video ***********");
    File compressedVideo = await uploadHandler.compressVideo();

    //upload to cloud
    _logger.i("********* Uploading to Cloud ***********");
    String videoSig = await uploadHandler.resignFile(compressedVideo);

    List<Future<String>> picSigFutures =
        pics.map((pic) async => signaturesProvider.getSignature(fileSystemRepository.getName(pic.path))).toList();
    List<String> picsSig = await Future.wait(picSigFutures);

    UploadChunkSignaturesRequest uploadChunkSignaturesRequest = UploadChunkSignaturesRequest(
      videoSig: videoSig,
      picturesSig: picsSig,
      metadataSig: metadataSig,
    );

    backendService.uploadChunk(video, pics, metaData, uploadChunkSignaturesRequest, progressCallback).then((_) {
        //deleting files in the directory of the video chunk.
      fileSystemRepository.deleteDirectoryFiles(chunkPath);
      notifyListeners();
    });
  }

  handlePlayButtonPress(context, int videoIndex) {
    return chunksPaths[videoIndex]; // Assuming chunksPaths contains video paths
  }

  Future<void> getChunks(String journeyId) async {
    final chunks = await backendService.getJourneyChunks(journeyId);
    chunksPaths = chunks;
    notifyListeners();
  }

  Future<File> download(String journeyId, int chunkIndex) async {
    File downloadedFile = await backendService.downloadChunk(journeyId, chunksPaths[chunkIndex]); //TODO: check if works
    notifyListeners();
    return downloadedFile;
  }
}
