import 'dart:io';

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:safety_eye_app/models/payloads/request/requests.dart';
import 'package:safety_eye_app/models/payloads/response/responses.dart';

import '../../environment_config.dart';

part 'api.g.dart';

@RestApi(baseUrl: EnvironmentConfig.BACKEND_URL)
abstract class BackendApi {
  factory BackendApi(Dio dio, {String baseUrl}) = _BackendApi;

  @POST('/auth/keyExchange')
  @Headers({'Content-Type': 'application/json'})
  Future<String> exchangeKey(@Body() KeyExchangeRequest keyRequest);

  @GET('/video/journeys')
  Future<JourneysResponse> getJourneys();

  @GET('/video/journeys/{journeyId}/chunks')
  Future<JourneyChunksResponse> getJourneyChunksById(
      @Path('journeyId') String journeyId);

  @GET('/video/download/{journeyId}/{chunkId}')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> downloadChunk(
      @Path('journeyId') String journeyId, @Path('chunkId') String chunkId);

  @POST('/video/upload')
  @MultiPart()
  Future<void> uploadChunk(
      @Part(name: "signatures") String signatures,
      @Part(name: 'video') File video,
      @Part(name: "pictures") List<File> pictures,
      @Part(name: "metadata") File metadata,
      @SendProgress() ProgressCallback? onSendProgress);

  @POST('/video/journeys/{journeyId}/chunks/{chunkId}/highlight')
  Future<void> highlightChunk(
      @Path('journeyId') String journeyId, @Path('chunkId') String chunkId);

  @POST('/video/journeys/{journeyId}/chunks/{chunkId}/unhighlight')
  Future<void> unhighlightChunk(
      @Path('journeyId') String journeyId, @Path('chunkId') String chunkId);
}
