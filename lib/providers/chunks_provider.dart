import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_eye_app/providers/providers.dart';

import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/payloads/request/requests.dart';
import '../services/BackendService.dart';
import '../repositories/file_system_repo.dart';
import '../services/compression_service.dart';

class ChunksProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  List<String> chunksPaths = [];
  final List<String?> thumbnails = [];
  final AuthenticationProvider authenticationProvider;
  final SignaturesProvider signaturesProvider;
  final FileSystemRepository fileSystemRepository;
  final BackendService backendService;
  final CompressionService compressionService;

  ChunksProvider(
      {required this.authenticationProvider,
      required this.backendService,
      required this.fileSystemRepository,
      required this.signaturesProvider,
      required this.compressionService});

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
      thumbnail = null;
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

  Future<void> handleHighlightsButtonPress(int videoIndex) async {}

  Future<void> handleCloudUploadButtonPress(int videoIndex) async {
    // got all the files
    File video = fileSystemRepository.getChunkVideo(chunksPaths[videoIndex]);
    _logger.i("fetch video file - path ${video.path}");
    List<File> pics =
        fileSystemRepository.getChunkPics(chunksPaths[videoIndex]);
    _logger.i("fetch pic files - length ${pics.length}");
    File metaData =
        fileSystemRepository.getChunkMetadata(chunksPaths[videoIndex]);
    _logger.i("fetch metadata file - path ${metaData.path}");
    bool verifyVideo = await verifySignature(video);
    bool verifyMetadata = await verifySignature(metaData);
    List<Future<bool>> verificationFutures =
        pics.map((file) => verifySignature(file)).toList();
    List<bool> verificationResults = await Future.wait(verificationFutures);
    bool verifyPics = verificationResults.every((result) => result);
    if (!(verifyPics && verifyMetadata && verifyVideo)) {
      throw Exception();
    }
    _logger.i("cool cool cool");
    // get video signature and verify it.

    //run AI model on video
    //marge AI metadata result with existing metadata
    //sign metadata
    //compress video and sign
    //upload to cloud
    final comVideo = await compressionService.compressVideo(video.path);

    File? compressVideo = comVideo?.file;
    Uint8List videoCoBytes =
        await fileSystemRepository.getUint8List(compressVideo!.path);

    await signaturesProvider.sign(
        fileSystemRepository.getName(compressVideo.path),
        base64Encode(videoCoBytes));

    String comVideoSign = await signaturesProvider
        .getSignature(fileSystemRepository.getName(compressVideo.path));

    String metaDataSign = await signaturesProvider
        .getSignature(fileSystemRepository.getName(metaData.path));

    List<Future<String>> picSignFutures = pics
        .map((pic) async => signaturesProvider
            .getSignature(fileSystemRepository.getName(pic.path)))
        .toList();

    List<String> picsSign = await Future.wait(picSignFutures);

    UploadChunkSignaturesRequest uploadChunkSignaturesRequest =
        UploadChunkSignaturesRequest(
      videoSig: comVideoSign,
      picturesSig: picsSign,
      metadataSig: metaDataSign,
    );

    backendService.uploadChunk(
        compressVideo, pics, metaData, uploadChunkSignaturesRequest, null);
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
    return backendService.downloadChunk(
        journeyId, chunksPaths[chunkIndex]);
  }

  Future<bool> verifySignature(File f) async {
    Uint8List stringFile = await fileSystemRepository.getUint8List(f.path);

    PublicKey publicKey = await signaturesProvider.getPublicKey();

    _logger.i("verifysignature. retreat publicKey: $publicKey");
    Signature signature0 =
        Signature(stringFile, publicKey: publicKey);

    _logger.i("verifysignature . signature created");
    bool verifysignature = await signaturesProvider.verifySignatureUint8List(
        stringFile, signature0);

    _logger.i("verifysignature: $verifysignature");
    return verifysignature;
  }
}
