
import 'package:json_annotation/json_annotation.dart';

part 'requests.g.dart';


@JsonSerializable()
class KeyExchangeRequest {
  final String key;

  KeyExchangeRequest({this.key = ''});

  factory KeyExchangeRequest.fromJson(Map<String, dynamic> json) => _$KeyExchangeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$KeyExchangeRequestToJson(this);

}