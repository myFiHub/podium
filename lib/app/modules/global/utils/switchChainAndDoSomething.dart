import 'package:get/get.dart';
import 'package:particle_base/particle_base.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

particle_switchAndAction<T>({
  required String chainIdToTemporarilySwitchTo,
  required Function action,
}) async {
  final originalChainInfo = await ParticleBase.getChainInfo();
  if (originalChainInfo.id.toString() == chainIdToTemporarilySwitchTo) {
    return await action();
  }
  final targetChainInfo =
      particleChainInfoByChainId(chainIdToTemporarilySwitchTo);
  if (targetChainInfo == null) {
    Toast.error(message: 'Invalid chain id');
    return null;
  }
  try {
    await ParticleBase.setChainInfo(targetChainInfo);
    final T res = await action();
    await ParticleBase.setChainInfo(originalChainInfo);
    return res;
  } catch (e) {
    log.e(e);
    Toast.error(message: 'Error occured while switching chain');
    return null;
  }
}
