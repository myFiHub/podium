import 'package:reown_appkit/modal/services/explorer_service/explorer_service_singleton.dart';
import 'package:reown_appkit/reown_appkit.dart';

String getChainIconUrl(ReownAppKitModalNetworkInfo chainInfo) {
  if (chainInfo.chainIcon != null && chainInfo.chainIcon!.contains('http')) {
    return chainInfo.chainIcon!;
  }
  final chainImageId =
      ReownAppKitModalNetworks.getNetworkIconId(chainInfo.chainId) ?? '';
  return explorerService.instance.getAssetImageUrl(chainImageId);
}
