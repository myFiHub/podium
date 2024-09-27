class Env {
  static const initialExternalWalletChainId =
      String.fromEnvironment("initialExternalWalletChainId");
  static const initialParticleWalletChainId =
      String.fromEnvironment("initialParticleWalletChainId");

  static const starsArenaAddress = String.fromEnvironment("starsArenaAddress");
  static const proxyAddress = String.fromEnvironment("proxyAddress");
  static const cheerBooAddress = String.fromEnvironment("cheerBooAddress");
  static const minimumCheerBooAmount =
      String.fromEnvironment("minimumCheerBooAmount");
  static const cheerBooTimeMultiplication =
      String.fromEnvironment("cheerBooTimeMultiplication");

  // from walletConnect
  static const projectId = String.fromEnvironment('projectId');
  // from particle auth
  static const particleProjectId = String.fromEnvironment("particleProjectId");
  static const particleClientKey = String.fromEnvironment("particleClientKey");
  static const particleAppId = String.fromEnvironment("particleAppId");
  static const environment = String.fromEnvironment("environment");
  static const jitsiServerUrl = String.fromEnvironment("jitsiServerUrl");
  static const appStoreUrl = String.fromEnvironment("appStoreUrl");
  static const baseDeepLinkUrl = String.fromEnvironment("baseDeepLinkUrl");
  static const chainNamespace = String.fromEnvironment("chainNamespace");
  static const VERSION =
      String.fromEnvironment("VERSION", defaultValue: '1.0.4');
}

const DEV = 'dev';
const PROD = 'prod';
const STAGE = 'stage';
