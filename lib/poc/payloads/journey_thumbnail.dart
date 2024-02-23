import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

part 'journey_thumbnail.g.dart';

@JsonSerializable()
class JourneyPayload {
  final String? journeyName;
  // final File? journeyThumbnail;

  const JourneyPayload({
    this.journeyName,
    // this.journeyThumbnail,
  });

  factory JourneyPayload.fromJson(Map<String, dynamic> json) => _$JourneyPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$JourneyPayloadToJson(this);

}
