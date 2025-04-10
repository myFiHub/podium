import 'package:json_annotation/json_annotation.dart';

part 'buy_sell_request.g.dart';

enum TradeType {
  buy,
  sell,
}

@JsonSerializable()
class BuySellPodiumPassRequest {
  final int count;
  final String podium_pass_owner_address;
  final String podium_pass_owner_uuid;
  final TradeType trade_type;
  final String tx_hash;

  BuySellPodiumPassRequest({
    required this.count,
    required this.podium_pass_owner_address,
    required this.podium_pass_owner_uuid,
    required this.trade_type,
    required this.tx_hash,
  });

  factory BuySellPodiumPassRequest.fromJson(Map<String, dynamic> json) =>
      _$BuySellPodiumPassRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BuySellPodiumPassRequestToJson(this);
}
