import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/models/payloads/request/requests.dart';
import 'package:safety_eye_app/providers/auth_provider.dart';
import 'package:safety_eye_app/repositories/file_system_repo.dart';
import 'package:safety_eye_app/services/api.dart';
import 'package:safety_eye_app/services/preferences_services.dart';

import '../models/payloads/response/responses.dart';

class BackendService {
  Logger log = Logger();
  final PreferencesService _preferencesService = PreferencesService();
  final FileSystemRepository fileSystemRepository;
  AuthenticationProvider authProvider;
  late Dio dio;
  late BackendApi api;
  bool isDev = false;

  BackendService(this.authProvider, this.fileSystemRepository) {
    var createdDio = Dio();
    createdDio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      options.headers['Authorization'] =
          'Bearer ${await authProvider.currentUser?.getIdToken() ?? ''}';
      return handler.next(options);
    }));
    createdDio.interceptors.add(LogInterceptor(responseBody: true));
    dio = createdDio;
    api = BackendApi(dio);
  }

  Future<String> exchangeKey(String key) async {
    if (isDev) return 'devKey';
    log.i('Exchanging key: $key');
    final requestKey = KeyExchangeRequest(key: key);
    return await api.exchangeKey(requestKey);
  }

  Future<JourneysResponse> getJourneys() async {
    if (isDev) {
      return JourneysResponse(journeys: []); // TODO - create a real mock
    }
    return await api.getJourneys();
  }

  Future<List<String>> getJourneyChunks(String journeyId) async {
    if (isDev) {
      return List.generate(
          5, (index) => 'chunk$index'); // TODO - create a real mock
    }
    final response = await api.getJourneyChunksById(journeyId);
    return response.chunks;
  }

  Future<File> downloadChunk(String journeyId, String chunkId) async {
    if (isDev) return File('test'); // TODO - create a real mock
    final chunkBytes = await api.downloadChunk(journeyId, chunkId);
    log.i("received chunkBytes: ${chunkBytes.length}");
    return await fileSystemRepository.downLoadChunk(chunkBytes, journeyId, chunkId);
  }

  Future<void> uploadChunk(
      File video,
      List<File> pictures,
      File metadata,
      UploadChunkSignaturesRequest signaturesRequest,
      ProgressCallback? progressCallback) async {
    if (isDev) return;
    var exchangeKey = await _preferencesService
        .getPrefOrDefault<String>(PreferencesKeys.exchangeKey);
    var sigRequest = UploadChunkSignaturesRequest(
        videoSig: signaturesRequest.videoSig,
        picturesSig: signaturesRequest.picturesSig,
        metadataSig: signaturesRequest.metadataSig,
        key: exchangeKey);
    await api.uploadChunk(json.encoder.convert(sigRequest.toJson()), video,
        pictures, metadata, progressCallback);
  }
}
