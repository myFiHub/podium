class StorageKeys {
  static final StorageKeys _singleton = StorageKeys._internal();
  factory StorageKeys() {
    return _singleton;
  }
  StorageKeys._internal();

  static final userId = 'userId';
  static final userFullName = 'userFullName';
  static final userEmail = 'userEmail';
  static final userAvatar = 'userAvatar';
  static final connectedWalletAddress = 'connectedWalletAddress';
  static final ignoredOrAcceptedVersion = 'ignoredOrAcceptedVersion';
  static final ongoingCallSortType = 'ongoingCallSortType';
  static final loginType = 'loginType';
}
