import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

enum ChainType {
  eip155,
  solana,
  kadena,
}

class ChainMetadata {
  final Color color;
  final ChainType type;
  final ReownAppKitModalNetworkInfo w3mChainInfo;

  const ChainMetadata({
    required this.color,
    required this.type,
    required this.w3mChainInfo,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChainMetadata &&
        other.color == color &&
        other.type == type &&
        other.w3mChainInfo == w3mChainInfo;
  }

  @override
  int get hashCode {
    return color.hashCode ^ type.hashCode ^ w3mChainInfo.hashCode;
  }
}
