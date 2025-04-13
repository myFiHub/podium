// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buy_sell_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuySellPodiumPassRequest _$BuySellPodiumPassRequestFromJson(
        Map<String, dynamic> json) =>
    BuySellPodiumPassRequest(
      count: (json['count'] as num).toInt(),
      podium_pass_owner_address: json['podium_pass_owner_address'] as String,
      podium_pass_owner_uuid: json['podium_pass_owner_uuid'] as String,
      trade_type: $enumDecode(_$TradeTypeEnumMap, json['trade_type']),
      tx_hash: json['tx_hash'] as String,
    );

Map<String, dynamic> _$BuySellPodiumPassRequestToJson(
        BuySellPodiumPassRequest instance) =>
    <String, dynamic>{
      'count': instance.count,
      'podium_pass_owner_address': instance.podium_pass_owner_address,
      'podium_pass_owner_uuid': instance.podium_pass_owner_uuid,
      'trade_type': _$TradeTypeEnumMap[instance.trade_type]!,
      'tx_hash': instance.tx_hash,
    };

const _$TradeTypeEnumMap = {
  TradeType.buy: 'buy',
  TradeType.sell: 'sell',
};
