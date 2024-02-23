

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:safety_eye_app/poc/payloads/request/requests.dart';

import '../environment_config.dart';

part 'BackendAPI.g.dart';

@RestApi(baseUrl: EnvironmentConfig.BACKEND_URL)
abstract class BackendApi {
  factory BackendApi(Dio dio, {String baseUrl}) = _BackendApi;

  @POST('/auth/keyExchange')
  @Headers({
    'Content-Type': 'application/json'
  })
  Future<String> exchangeKey(@Body() KeyExchangeRequest keyRequest);


  @GET('/video/journey')
  @DioResponseType(ResponseType.bytes)
  Future<dynamic> getJourneys();

  @GET('/video/journey/{id}')
  @DioResponseType(ResponseType.bytes)
  Future<dynamic> getJourney(@Path('id') String id);



}