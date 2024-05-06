import 'package:json_annotation/json_annotation.dart';

part 'responses.g.dart';

@JsonSerializable()
class JourneysResponse {
  List<String> journeys;

  JourneysResponse({
    this.journeys = const <String>[],
  });

  factory JourneysResponse.fromJson(Map<String, dynamic> json) => _$JourneysResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JourneysResponseToJson(this);
}

@JsonSerializable()
class JourneyChunksResponse {
  List<String> chunks;

  JourneyChunksResponse({
    this.chunks = const <String>[],
  });

  factory JourneyChunksResponse.fromJson(Map<String, dynamic> json) => _$JourneyChunksResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JourneyChunksResponseToJson(this);
}
