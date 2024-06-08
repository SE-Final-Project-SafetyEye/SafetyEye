import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/environment_config.dart';
import 'package:safety_eye_app/models/payloads/request/requests.dart';
import 'package:safety_eye_app/providers/signatures_provider.dart';
import 'package:safety_eye_app/repositories/file_system_repo.dart';
import 'package:safety_eye_app/services/object_detection_service.dart';
import 'package:video_compress/video_compress.dart';

import '../services/compression_service.dart';

class UploadHandler {
  final Logger _logger = Logger();
  SignaturesProvider sigProvider;
  FileSystemRepository filesystemRepo;
  File video;
  List<File> pics;
  File metadata;

  UploadHandler(this.sigProvider, this.filesystemRepo, this.video, this.pics, this.metadata);


  Future<bool> verifySignatures() async {
    bool verifyResult = await _verifyVideo();
    if (!verifyResult) {
      return false;
    }
    verifyResult = await _verifyPics();
    if (!verifyResult) {
      return false;
    }
    verifyResult = await _verifyMetadata();
    if (!verifyResult) {
      return false;
    }
    return true;
  }


  Future<bool> _verifyVideo() async {
    String videoSig = await sigProvider.getSignature(filesystemRepo.getName(video.path));
    Uint8List videoBytes = await video.readAsBytes();

    try {
      bool verifyResult = await sigProvider.verifySignature(videoBytes, base64Decode(videoSig));
      _logger.i("verifyResult: $verifyResult");
      if (!verifyResult) {
        throw Exception("Signature verification failed, data maybe corrupt");
      } else {
        _logger.i("Signature verified");
        return true;
      }
    } catch (e) {
      _logger.e('Error verifying signature: $e');
      return false;
    }
  }

  Future<bool> _verifyPic(File pic) async {
    String picSig = await sigProvider.getSignature(filesystemRepo.getName(pic.path));
    Uint8List picBytes = await pic.readAsBytes();

    try {
      bool verifyResult = await sigProvider.verifySignature(picBytes, base64Decode(picSig));
      _logger.i("verifyResult: $verifyResult");
      if (!verifyResult) {
        throw Exception("Signature verification failed, data maybe corrupt");
      } else {
        _logger.i("Video Signature verified");
        return true;
      }
    } catch (e) {
      _logger.e('Error verifying signature: $e');
      return false;
    }
  }

  Future<bool> _verifyPics() async {
    List<Future<bool>> picsVerifyResults = pics.map((pic) => _verifyPic(pic)).toList();

    try {
      List<bool> allPicsVerifiedResult = await Future.wait(picsVerifyResults);
      bool allResult = allPicsVerifiedResult.every((picsVerifyResult) => picsVerifyResult);
      if (!allResult) {
        throw Exception("Pics verification failed, data maybe corrupt");
      } else {
        _logger.i("Pics signatures verified");
        return true;
      }
    } catch (e) {
      _logger.e('Error verifying pics: $e');
      return false;
    }
  }

  Future<bool> _verifyMetadata() async {
    String metadataSig = await sigProvider.getSignature(filesystemRepo.getName(metadata.path));
    Uint8List metadataBytes = await metadata.readAsBytes();

    try {
      bool verifyResult = await sigProvider.verifySignature(metadataBytes, base64Decode(metadataSig));
      _logger.i("verifyResult: $verifyResult");
      if (!verifyResult) {
        throw Exception("Signature verification failed, data maybe corrupt");
      } else {
        _logger.i("Metadata Signature verified");
        return true;
      }
    } catch (e) {
      _logger.e('Error verifying signature: $e');
      return false;
    }
  }

  Future<File> compressVideo() async {
    final compressionService = CompressionService();

    MediaInfo? compressedFile = await compressionService.compressVideo(video.path);

    if (compressedFile == null) {
      throw Exception("Could not compress video");
    }
    if (compressedFile.file == null) {
      throw Exception("Compressed file was not created");
    } else {
      return compressedFile.file!;
    }
  }

  Future<String> resignFile(File file) async {
    XFile compressedXFile = XFile(file.path);
    Uint8List fileBytes = await compressedXFile.readAsBytes();
    Signature signature = await sigProvider.sign(compressedXFile.name, base64Encode(fileBytes), saveToDb: false);

    return base64Encode(signature.bytes);
  }

  //todo: need to merge them
  Future<File> mergeMetadata(File metadata, File modelMetadata) async {
    return metadata;
  }

  Future<void> runObjectDetectionModel() async {
    ModelObjectDetectionSingleton().addWork(video.path);

    // mergeMetadata(metadata, modelMetadata); ---> save on top of the metadata file
  }

}
