class StorageKeys {
  static final StorageKeys _singleton = StorageKeys._internal();
  factory StorageKeys() {
    return _singleton;
  }
  StorageKeys._internal();

  static const userId = 'userId';
  static const userFullName = 'userFullName';
  static const userEmail = 'userEmail';
  static const userAvatar = 'userAvatar';
  static const ignoredOrAcceptedVersion = 'ignoredOrAcceptedVersion';
  static const ongoingCallSortType = 'ongoingCallSortType';
  static const loginType = 'loginType';
  static const rememberSelectedWallet = 'rememberWallet';
  static const selectedWalletName = 'selectedWalletName';
  static const externalWalletChainId = 'externalWalletChainId';
  static const showArchivedGroups = 'showArchivedGroups';
}
