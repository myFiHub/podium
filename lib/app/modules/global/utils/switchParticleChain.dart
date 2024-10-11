import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/utils/getContract.dart';
import 'package:particle_base/particle_base.dart';

Future<bool> temporarilyChangeParticleNetwork(String chainId) async {
  final savedChainId = (await ParticleBase.getChainId()).toString();
  if (savedChainId == chainId) {
    return true;
  }
  final chainInfo = particleChainInfoByChainId(chainId);

  await ParticleBase.setChainInfo(chainInfo);
  return true;
}

Future<bool> switchBackToSavedParticleNetwork() async {
  final savedChainId = particleChianId;
  final chainInfo = particleChainInfoByChainId(savedChainId);
  await ParticleBase.setChainInfo(chainInfo);
  return true;
}

Future<ChainInfo> getCurrentParticleChain() async {
  final chainId = await ParticleBase.getChainId();
  return particleChainInfoByChainId(chainId.toString());
}
