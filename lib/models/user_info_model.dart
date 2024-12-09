class UserInfoModel {
  late String id;
  late String fullName;
  late String email;
  late String avatar;
  late String evm_externalWalletAddress;
  late List<String> following;
  String? lowercasename;
  late String evmInternalWalletAddress;
  String aptosInternalWalletAddress = '';
  late int numberOfFollowers;
  bool isOver18 = false;
  String referrer = '';
  String? loginType;
  String? loginTypeIdentifier;

  static String idKey = 'id';
  static String fullNameKey = 'fullName';
  static String emailKey = 'email';
  static String avatarUrlKey = 'avatar';
  static String evm_externalWalletAddressKey = 'evm_externalWalletAddress';
  static String followingKey = 'following';
  static String numberOfFollowersKey = 'numberOfFollowers';
  static String lowercasenameKey = 'lowercasename';
  static String isOver18Key = 'isOver18';
  static String loginTypeKey = 'loginType';
  static String loginTypeIdentifierKey = 'loginTypeIdentifier';
  static String evmInternalWalletAddressKey = 'evmInternalWalletAddress';
  static String aptosInternalWalletAddressKey = 'aptosInternalWalletAddress';
  static String referrerKey = 'referrer';

  UserInfoModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.evm_externalWalletAddress,
    required this.following,
    required this.numberOfFollowers,
    required this.evmInternalWalletAddress,
    this.aptosInternalWalletAddress = '',
    this.lowercasename,
    this.isOver18 = false,
    this.loginType,
    this.loginTypeIdentifier,
    this.referrer = '',
  });

  String get defaultWalletAddress {
    final walletAddress = evm_externalWalletAddress;
    if (walletAddress.isEmpty) {
      if (evmInternalWalletAddress.isEmpty) {
        return '';
      }
      return evmInternalWalletAddress;
    }
    return walletAddress;
  }

  UserInfoModel.fromJson(Map<String, dynamic> json) {
    id = json[idKey];
    fullName = json[fullNameKey];
    email = json[emailKey];
    avatar = json[avatarUrlKey];
    evm_externalWalletAddress = json[evm_externalWalletAddressKey] ?? '';
    following = json[followingKey] ?? [];
    numberOfFollowers = json[numberOfFollowersKey] ?? 0;
    lowercasename = json[lowercasenameKey] ?? fullName.toLowerCase();
    isOver18 = json[isOver18Key] ?? false;
    loginType = json[loginTypeKey];
    referrer = json[referrerKey] ?? '';
    evmInternalWalletAddress = json[evmInternalWalletAddressKey];
    aptosInternalWalletAddress = json[aptosInternalWalletAddressKey] ?? '';
    loginTypeIdentifier = json[loginTypeIdentifierKey];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[idKey] = id;
    data[fullNameKey] = fullName;
    data[emailKey] = email;
    data[avatarUrlKey] = avatar;
    data[evm_externalWalletAddressKey] = evm_externalWalletAddress;
    data[evmInternalWalletAddressKey] = evmInternalWalletAddress;
    data[aptosInternalWalletAddressKey] = aptosInternalWalletAddress;
    data[followingKey] = following;
    data[numberOfFollowersKey] = numberOfFollowers;
    data[lowercasenameKey] = lowercasename ?? fullName.toLowerCase();
    data[isOver18Key] = isOver18;
    data[loginTypeKey] = loginType;
    data[referrerKey] = referrer;
    data[loginTypeIdentifierKey] = loginTypeIdentifier;
    return data;
  }

  copyWith({
    String? id,
    String? fullName,
    String? email,
    String? avatar,
    String? evm_externalWalletAddress,
    List<String>? following,
    int? numberOfFollowers,
    String? lowercasename,
    String? evmInternalWalletAddress,
    String? aptosInternalWalletAddress,
    bool? isOver18,
    String? loginType,
    String? loginTypeIdentifier,
    String? referrer,
  }) {
    return UserInfoModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      evm_externalWalletAddress:
          evm_externalWalletAddress ?? this.evm_externalWalletAddress,
      following: following ?? this.following,
      numberOfFollowers: numberOfFollowers ?? this.numberOfFollowers,
      lowercasename: lowercasename ?? this.lowercasename,
      aptosInternalWalletAddress:
          aptosInternalWalletAddress ?? this.aptosInternalWalletAddress,
      isOver18: isOver18 ?? this.isOver18,
      loginType: loginType ?? this.loginType,
      evmInternalWalletAddress:
          evmInternalWalletAddress ?? this.evmInternalWalletAddress,
      loginTypeIdentifier: loginTypeIdentifier ?? this.loginTypeIdentifier,
      referrer: referrer ?? this.referrer,
    );
  }
}
