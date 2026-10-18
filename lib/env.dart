import 'package:podium/contracts/chainIds.dart';

/// Configuration compiled in at build time with
/// `--dart-define-from-file=env/<environment>.env` (see README).
/// Nothing is read from bundled asset files at runtime.
class Env {
  static const oneSignalApiKey = String.fromEnvironment('ONESIGNAL_API_KEY');
  static const initialExternalWalletChainId =
      String.fromEnvironment('INITIAL_EXTERNAL_WALLET_CHAIN_ID');

  static const starsArenaAddress_Avalanche_Mainnet =
      String.fromEnvironment('STARS_ARENA_ADDRESS_AVALANCHE_MAINNET');
  static const starsArenaProxyAddress_Avalanche_Mainnet =
      String.fromEnvironment('STARS_ARENA_PROXY_ADDRESS_AVALANCHE_MAINNET');
  static const friendtechAddress_BaseChain_Mainnet =
      String.fromEnvironment('FRIENDTECH_ADDRESS_BASECHAIN_MAINNET');

  static const minimumCheerBooAmount =
      String.fromEnvironment('MINIMUM_CHEERBOO_AMOUNT');
  static const cheerBooTimeMultiplication =
      String.fromEnvironment('CHEERBOO_TIME_MULTIPLICATION');

  // from walletConnect
  static const projectId = String.fromEnvironment('PROJECT_ID');
  static const web3AuthClientId = String.fromEnvironment('WEB3_AUTH_CLIENT_ID');
  static const environment = String.fromEnvironment('ENVIRONMENT');
  static const jitsiServerUrl = String.fromEnvironment('JITSI_SERVER_URL');
  static const appStoreUrl = String.fromEnvironment('APP_STORE_URL');
  static const baseDeepLinkUrl = String.fromEnvironment('BASE_DEEP_LINK_URL');
  static const chainNamespace = String.fromEnvironment('CHAIN_NAMESPACE');
  static const albyApiKey = String.fromEnvironment('ALBY_API_KEY');

  static const lumaApiKey = String.fromEnvironment('LUMA_API_KEY');

  static const fihubAddress_Avalanche_MainNet =
      String.fromEnvironment('FIHUB_ADDRESS_AVALANCHE_MAINNET');

  static const fihubAddress_Aptos = String.fromEnvironment('FIHUB_ADDRESS_APTOS');

  static const VERSION = String.fromEnvironment('VERSION', defaultValue: '1.1.5');

  static const podimBackendBaseUrl =
      String.fromEnvironment('PODIM_BACKEND_BASE_URL');

  static const websocketAddress = String.fromEnvironment('WEBSOCKET_ADDRESS');

  static const _required = {
    'ONESIGNAL_API_KEY': oneSignalApiKey,
    'INITIAL_EXTERNAL_WALLET_CHAIN_ID': initialExternalWalletChainId,
    'STARS_ARENA_ADDRESS_AVALANCHE_MAINNET': starsArenaAddress_Avalanche_Mainnet,
    'STARS_ARENA_PROXY_ADDRESS_AVALANCHE_MAINNET':
        starsArenaProxyAddress_Avalanche_Mainnet,
    'FRIENDTECH_ADDRESS_BASECHAIN_MAINNET': friendtechAddress_BaseChain_Mainnet,
    'MINIMUM_CHEERBOO_AMOUNT': minimumCheerBooAmount,
    'CHEERBOO_TIME_MULTIPLICATION': cheerBooTimeMultiplication,
    'PROJECT_ID': projectId,
    'WEB3_AUTH_CLIENT_ID': web3AuthClientId,
    'ENVIRONMENT': environment,
    'JITSI_SERVER_URL': jitsiServerUrl,
    'APP_STORE_URL': appStoreUrl,
    'BASE_DEEP_LINK_URL': baseDeepLinkUrl,
    'CHAIN_NAMESPACE': chainNamespace,
    'ALBY_API_KEY': albyApiKey,
    'LUMA_API_KEY': lumaApiKey,
    'FIHUB_ADDRESS_AVALANCHE_MAINNET': fihubAddress_Avalanche_MainNet,
    'FIHUB_ADDRESS_APTOS': fihubAddress_Aptos,
    'PODIM_BACKEND_BASE_URL': podimBackendBaseUrl,
    'WEBSOCKET_ADDRESS': websocketAddress,
  };

  /// Fails fast when the app was built without its environment file.
  static void ensureConfigured() {
    final missing = [
      for (final entry in _required.entries)
        if (entry.value.isEmpty) entry.key,
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing build configuration: ${missing.join(', ')}. '
        'Build with --dart-define-from-file=env/<environment>.env',
      );
    }
  }

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

  static String? friendtechAddress(String chainId) {
    if (chainId == baseChainId) {
      return friendtechAddress_BaseChain_Mainnet;
    } else {
      return null;
    }
  }
}

const DEVELOPMENT = 'development';
const PRODUCTION = 'production';
