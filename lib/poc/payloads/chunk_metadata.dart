
import 'package:json_annotation/json_annotation.dart';

part 'chunk_metadata.g.dart';

@JsonSerializable()
class ChunkMetadata {

  ChunkMetadata();

  factory ChunkMetadata.fromJson(Map<String, dynamic> json) => _$ChunkMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ChunkMetadataToJson(this);
}