// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'responses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JourneysResponse _$JourneysResponseFromJson(Map<String, dynamic> json) =>
    JourneysResponse(
      journeys: (json['journeys'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$JourneysResponseToJson(JourneysResponse instance) =>
    <String, dynamic>{
      'journeys': instance.journeys,
    };

JourneyChunksResponse _$JourneyChunksResponseFromJson(
        Map<String, dynamic> json) =>
    JourneyChunksResponse(
      chunks: (json['chunks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$JourneyChunksResponseToJson(
        JourneyChunksResponse instance) =>
    <String, dynamic>{
      'chunks': instance.chunks,
    };
