import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safety_eye_app/poc/payloads/request/requests.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

import 'BackendAPI.dart';
import 'payloads/response/responses.dart';

class BackendService {
  Logger log = Logger();
  User? currentUser;
  late Dio dio;
  late BackendApi api;

  BackendService(this.currentUser) {
    var createdDio = Dio();
    createdDio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      options.headers['Authorization'] = 'Bearer ${await currentUser?.getIdToken() ?? ''}';
      return handler.next(options);
    }));
    dio = createdDio;
    api = BackendApi(dio);
  }

  Future<String> exchangeKey(String key) async {
    log.i('Exchanging key: $key');
    final requestKey = KeyExchangeRequest(key: key);
    return await api.exchangeKey(requestKey);
  }

  Future<JourneysResponse> getJourneys() async {
    return await api.getJourneys();
  }

  Future<List<String>> getJourneyChunks(String journeyId) async {
    final response = await api.getJourneyChunksById(journeyId);
    return response.chunks;
  }

  Future<File> downloadChunk(String journeyId, String chunkId) async {
    final chunkBytes = await api.downloadChunk(journeyId, chunkId);
    final appDirectory = await getApplicationDocumentsDirectory();
    File chunkFile = File('${appDirectory.path}/$chunkId');
    return await chunkFile.writeAsBytes(chunkBytes);
  }

  Future<void> uploadChunk(
      File video, List<File> pictures, File metadata, UploadChunkSignaturesRequest signaturesRequest) async {
    try {
      await api.uploadChunk(json.encoder.convert(signaturesRequest.toJson()), video, pictures, metadata);
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
