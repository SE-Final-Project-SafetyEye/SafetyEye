import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:safety_eye_app/poc/payloads/request/requests.dart';

import 'BackendAPI.dart';

class BackendService {
  Logger log = Logger();
  User currentUser;
  late Dio dio;
  late BackendApi api;

  BackendService(this.currentUser) {
    var createdDio = Dio();
    createdDio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      options.headers['Authorization'] = 'Bearer ${await currentUser.getIdToken()}';
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
}
