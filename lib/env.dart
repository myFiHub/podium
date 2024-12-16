import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/contracts/chainIds.dart';

class Env {
  static final initialExternalWalletChainId =
      dotenv.env['INITIAL_EXTERNAL_WALLET_CHAIN_ID']!;

  static final starsArenaAddress_Avalanche_Mainnet =
      dotenv.env['STARS_ARENA_ADDRESS_AVALANCHE_MAINNET']!;
  static final starsArenaProxyAddress_Avalanche_Mainnet =
      dotenv.env['STARS_ARENA_PROXY_ADDRESS_AVALANCHE_MAINNET']!;
  static final friendtechAddress_BaseChain_Mainnet =
      dotenv.env['FRIENDTECH_ADDRESS_BASECHAIN_MAINNET']!;
  static final cheerBooAddress_Movement_Devnet =
      dotenv.env['CHEERBOO_ADDRESS_MOVEMENT_DEVNET']!;
  static final minimumCheerBooAmount = dotenv.env['MINIMUM_CHEERBOO_AMOUNT']!;
  static final cheerBooTimeMultiplication =
      dotenv.env['CHEERBOO_TIME_MULTIPLICATION']!;

  // from walletConnect
  static final projectId = dotenv.env['PROJECT_ID']!;
  static final web3AuthClientId = dotenv.env['WEB3_AUTH_CLIENT_ID']!;
  static final environment = dotenv.env['ENVIRONMENT']!;
  static final jitsiServerUrl = dotenv.env['JITSI_SERVER_URL']!;
  static final appStoreUrl = dotenv.env['APP_STORE_URL']!;
  static final baseDeepLinkUrl = dotenv.env['BASE_DEEP_LINK_URL']!;
  static final chainNamespace = dotenv.env['CHAIN_NAMESPACE']!;
  static final albyApiKey = dotenv.env['ALBY_API_KEY']!;

  static final fihubAddress_Avalanche_MainNet =
      dotenv.env['FIHUB_ADDRESS_AVALANCHE_MAINNET']!;

  static final cheerBooAptosAddress = dotenv.env['CHEERBOO_APTOS_ADDRESS']!;

  static final VERSION = dotenv.env['VERSION'] ?? '1.0.8';

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
    if (chainId == movementChain.chainId) {
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
