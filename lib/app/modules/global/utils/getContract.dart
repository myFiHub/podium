import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/contracts/cheerBoo.dart';
import 'package:podium/contracts/friendTech.dart';
import 'package:podium/contracts/starsArena.dart';
import 'package:podium/env.dart' as Environment;
import 'package:particle_base/model/chain_info.dart' as ChainInfo;

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
        if (starsArenaAddress(chainId) != ZERO_ADDRESS) {
          deployedContract = starsArenaContract(chainId);
        }
      }
      break;
    case Contracts.cheerboo:
      {
        if (cheerBooAddress(chainId) != ZERO_ADDRESS) {
          deployedContract = cheerBooContract(chainId);
        }
      }
      break;
    case Contracts.friendTech:
      {
        if (friendTechAddress(chainId) != ZERO_ADDRESS) {
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

    Get.snackbar(
      "Error",
      "Contract is not deployed on ${chainNameById(chainId)}",
      colorText: Colors.red,
    );
  }

  return deployedContract;
}

chainNameById(String chainId) {
  final name =
      ReownAppKitModalNetworks.getNetworkById(Env.chainNamespace, chainId)
          ?.name;
  if (name == null) {
    return "Unknown";
  }
  return name;
}

ChainInfo.ChainInfo particleChainInfoByChainId(String chainId) {
  return ChainInfo.ChainInfo.getChain(
        int.parse(chainId),
        chainNameById(chainId),
      ) ??
      movementChainOnParticle;
}

String friendTechAddress(String chainId) {
  final aadress = Environment.Env.friendtechAddress(chainId);
  if (aadress == null || aadress.isEmpty) {
    return ZERO_ADDRESS;
  }
  return aadress;
}

friendTechContract(String chainId) {
  return _getContract(
    abi: FriendTechContract.abi,
    address: friendTechAddress(chainId),
    name: "FriendtechSharesV1",
  );
}

String starsArenaAddress(String chainId) {
  // we should call the proxy contract for StarsArena, since StarsArena is upgradeable
  final address = Environment.Env.starsArenaProxyAddress(particleChianId);
  if (address == null || address.isEmpty) {
    return ZERO_ADDRESS;
  }
  return address;
}

DeployedContract? starsArenaContract(String chainId) {
  final starsArenaAddressString = starsArenaAddress(chainId);
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

String cheerBooAddress(String chainId) {
  final address = Environment.Env.cheerBooAddress(externalWalletChianId);
  if (address == null || address.isEmpty) {
    return ZERO_ADDRESS;
  }
  return address;
}

DeployedContract? cheerBooContract(String chainId) {
  final cheerBooAddressString = cheerBooAddress(chainId);
  return _getContract(
    abi: CheerBoo.abi,
    address: cheerBooAddressString,
    name: "CheerBoo",
  );
}

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
