import 'dart:convert';

import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/contracts/cheerBoo.dart';
import 'package:podium/contracts/friendTech.dart';
import 'package:podium/contracts/starsArena.dart';
import 'package:podium/env.dart' as Environment;
import 'package:podium/env.dart';
import 'package:podium/utils/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';

enum Contracts {
  starsArena,
  cheerboo,
  friendTech,
}

DeployedContract? getDeployedContract(
    {required Contracts contract, required String chainId}) {
  DeployedContract? deployedContract = null;
  switch (contract) {
    case Contracts.starsArena:
      {
        if (_starsArenaAddress(chainId) != ZERO_ADDRESS) {
          deployedContract = starsArenaContract(chainId);
        }
      }
      break;
    case Contracts.cheerboo:
      {
        if (_cheerBooAddress(chainId) != ZERO_ADDRESS) {
          deployedContract = cheerBooContract(chainId);
        }
      }
      break;
    case Contracts.friendTech:
      {
        if (_friendTechAddress(chainId) != ZERO_ADDRESS) {
          deployedContract = friendTechContract(chainId);
        }
      }
    default:
      {
        log.e("Invalid contract");
        deployedContract = null;
      }
  }
  if (deployedContract == null) {
    log.e("Contract not deployed");
    final chainName =
        ReownAppKitModalNetworks.getNetworkById(Env.chainNamespace, chainId)!
            .name;
    Get.snackbar("Error", "Contract is not deployed on $chainName");
  }

  return deployedContract;
}

_friendTechAddress(String chainId) {
  final aadress = Environment.Env.friendtechAddress(chainId);
  if (aadress == null || aadress.isEmpty) {
    return ZERO_ADDRESS;
  }
  return aadress;
}

friendTechContract(String chainId) {
  return _getContract(
    abi: FriendTechContract.abi,
    address: _friendTechAddress(chainId),
    name: "FriendtechSharesV1",
  );
}

String _starsArenaAddress(String chainId) {
  // we should call the proxy contract for StarsArena, since StarsArena is upgradeable
  final address = Environment.Env.starsArenaProxyAddress(particleChianId);
  if (address == null || address.isEmpty) {
    return ZERO_ADDRESS;
  }
  return address;
}

DeployedContract? starsArenaContract(String chainId) {
  final starsArenaAddressString = _starsArenaAddress(chainId);
  final contract = _getContract(
    abi: StarsArenaSmartContract.abi,
    address: starsArenaAddressString,
    name: "StarsArena",
  );
  return contract;
}

DeployedContract _getContract(
    {required abi, required String address, required String name}) {
  return DeployedContract(
    ContractAbi.fromJson(
      jsonEncode(abi),
      name,
    ),
    EthereumAddress.fromHex(address),
  );
}

String _cheerBooAddress(String chainId) {
  final address = Environment.Env.cheerBooAddress(externalWalletChianId);
  if (address == null || address.isEmpty) {
    return ZERO_ADDRESS;
  }
  return address;
}

DeployedContract? cheerBooContract(String chainId) {
  final cheerBooAddressString = _cheerBooAddress(chainId);
  return _getContract(
    abi: CheerBoo.abi,
    address: cheerBooAddressString,
    name: "CheerBoo",
  );
}

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
