import 'package:get/get.dart';
import 'package:particle_base/particle_base.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:podium/env.dart' as Environment;

particle_switchAndAction<T>(
    {required String chainIdToTemporarilySwitchTo,
    required Function action}) async {
  final originalChainInfo = await ParticleBase.getChainInfo();
  final targetChainInfo = ChainInfo.getChain(
    int.parse(chainIdToTemporarilySwitchTo),
    ReownAppKitModalNetworks.getNetworkById(
      Environment.Env.chainNamespace,
      chainIdToTemporarilySwitchTo,
    )!
        .name,
  );
  if (targetChainInfo == null) {
    Get.snackbar('Error', 'Invalid chain id');
    return;
  }
  try {
    await ParticleBase.setChainInfo(targetChainInfo);
    await action();
    await ParticleBase.setChainInfo(originalChainInfo);
    return true;
  } catch (e) {
    Get.snackbar('Error', 'Error occured while switching chain');
    return false;
  }
}
