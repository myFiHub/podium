import 'package:web3modal_flutter/models/w3m_chain_info.dart';
import 'package:web3modal_flutter/services/explorer_service/explorer_service_singleton.dart';
import 'package:web3modal_flutter/utils/asset_util.dart';

String getChainIconUrl(W3MChainInfo chainInfo) {
  if (chainInfo.chainIcon != null && chainInfo.chainIcon!.contains('http')) {
    return chainInfo.chainIcon!;
  }
  final chainImageId = AssetUtil.getChainIconId(chainInfo.chainId) ?? '';
  return explorerService.instance.getAssetImageUrl(chainImageId);
}
