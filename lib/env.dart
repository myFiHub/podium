import 'package:podium/contracts/chainIds.dart';

class Env {
  static const initialExternalWalletChainId =
      String.fromEnvironment("initialExternalWalletChainId");

  static const starsArenaAddress_Avalanche_Mainnet =
      String.fromEnvironment("starsArenaAddress_Avalanche_Mainnet");
  static const starsArenaProxyAddress_Avalanche_Mainnet =
      String.fromEnvironment("starsArenaProxyAddress_Avalanche_Mainnet");
  static const friendtechAddress_BaseChain_Mainnet =
      String.fromEnvironment("friendtechAddress_BaseChain_Mainnet");
  static const cheerBooAddress_Movement_Devnet =
      String.fromEnvironment("cheerBooAddress_Movement_Devnet");
  static const minimumCheerBooAmount =
      String.fromEnvironment("minimumCheerBooAmount");
  static const cheerBooTimeMultiplication =
      String.fromEnvironment("cheerBooTimeMultiplication");

  // from walletConnect
  static const projectId = String.fromEnvironment('projectId');
  static const web3AuthClientId = String.fromEnvironment("web3AuthClientId");
  static const environment = String.fromEnvironment("environment");
  static const jitsiServerUrl = String.fromEnvironment("jitsiServerUrl");
  static const appStoreUrl = String.fromEnvironment("appStoreUrl");
  static const baseDeepLinkUrl = String.fromEnvironment("baseDeepLinkUrl");
  static const chainNamespace = String.fromEnvironment("chainNamespace");
  static const albyApiKey = String.fromEnvironment("alby_apiKey");

  static const fihubAddress_Avalanche_MainNet =
      String.fromEnvironment("fihubAddress_Avalanche_MainNet");

  static const VERSION =
      String.fromEnvironment("VERSION", defaultValue: '1.0.8');

  static String? starsArenaAddress(String chainId) {
    if (chainId == avalancheChainId) {
      return starsArenaAddress_Avalanche_Mainnet;
    } else {
      return null;
    }
  }

  static String? starsArenaProxyAddress(String chainId) {
    if (chainId == avalancheChainId) {
      return starsArenaProxyAddress_Avalanche_Mainnet;
    } else {
      return null;
    }
  }

  static String? fihubAddress(String chainId) {
    if (chainId == avalancheChainId) {
      return fihubAddress_Avalanche_MainNet;
    } else {
      return null;
    }
  }

  static String? cheerBooAddress(String chainId) {
    if (chainId == movementChainId) {
      return cheerBooAddress_Movement_Devnet;
    } else {
      return null;
    }
  }

  static String? friendtechAddress(String chainId) {
    if (chainId == baseChainId) {
      return friendtechAddress_BaseChain_Mainnet;
    } else {
      return null;
    }
  }
}

const DEV = 'dev';
const PROD = 'prod';
const STAGE = 'stage';
