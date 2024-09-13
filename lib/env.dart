class Env {
  static const chainId = String.fromEnvironment("chainId");
  static const starsArenaAddress = String.fromEnvironment("starsArenaAddress");
  static const proxyAddress = String.fromEnvironment("proxyAddress");
  static const cheerBooAddress = String.fromEnvironment("cheerBooAddress");
  static const minimumCheerBooAmount =
      String.fromEnvironment("minimumCheerBooAmount");
  static const cheerBooTimeMultiplication =
      String.fromEnvironment("cheerBooTimeMultiplication");

  // from walletConnect
  static const projectId = String.fromEnvironment('projectId');
  // from CometChat
  // static const cometChatAppId = String.fromEnvironment("cometChatAppId");
  // static const cometChatRegion = String.fromEnvironment("cometChatRegion");
  // static const cometChatAuthKey = String.fromEnvironment("cometChatAuthKey");
  static const cometChatRestApiKey =
      String.fromEnvironment("cometChatRestApiKey");
  // from particle auth
  static const particleProjectId = String.fromEnvironment("particleProjectId");
  static const particleClientKey = String.fromEnvironment("particleClientKey");
  static const particleAppId = String.fromEnvironment("particleAppId");
  static const environment = String.fromEnvironment("environment");
  static const jitsiServerUrl = String.fromEnvironment("jitsiServerUrl");
  static const appStoreUrl = String.fromEnvironment("appStoreUrl");
  static const baseDeepLinkUrl = String.fromEnvironment("baseDeepLinkUrl");
  static const VERSION =
      String.fromEnvironment("VERSION", defaultValue: '1.0.2');
}

const DEV = 'dev';
const PROD = 'prod';
const STAGE = 'stage';
