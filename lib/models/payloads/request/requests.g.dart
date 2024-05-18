// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyExchangeRequest _$KeyExchangeRequestFromJson(Map<String, dynamic> json) =>
    KeyExchangeRequest(
      key: json['key'] as String? ?? '',
    );

Map<String, dynamic> _$KeyExchangeRequestToJson(KeyExchangeRequest instance) =>
    <String, dynamic>{
      'key': instance.key,
    };

UploadChunkSignaturesRequest _$UploadChunkSignaturesRequestFromJson(
        Map<String, dynamic> json) =>
    UploadChunkSignaturesRequest(
      videoSig: json['videoSig'] as String? ?? '',
      picturesSig: (json['picturesSig'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadataSig: json['metadataSig'] as String? ?? '',
      key: json['key'] as String? ?? '',
    );

Map<String, dynamic> _$UploadChunkSignaturesRequestToJson(
        UploadChunkSignaturesRequest instance) =>
    <String, dynamic>{
      'videoSig': instance.videoSig,
      'picturesSig': instance.picturesSig,
      'metadataSig': instance.metadataSig,
      'key': instance.key,
    };
