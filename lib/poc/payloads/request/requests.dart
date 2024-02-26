
import 'package:json_annotation/json_annotation.dart';

part 'requests.g.dart';


@JsonSerializable()
class KeyExchangeRequest {
  final String key;

  KeyExchangeRequest({this.key = ''});

  factory KeyExchangeRequest.fromJson(Map<String, dynamic> json) => _$KeyExchangeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$KeyExchangeRequestToJson(this);

}

@JsonSerializable()
class UploadChunkSignaturesRequest {
  final String videoSig;
  final List<String> picturesSig;
  final String metadataSig;
  final String key;

  UploadChunkSignaturesRequest({this.videoSig = '', this.picturesSig = const [], this.metadataSig = '', this.key = ''});

  factory UploadChunkSignaturesRequest.fromJson(Map<String, dynamic> json) => _$UploadChunkSignaturesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UploadChunkSignaturesRequestToJson(this);

}