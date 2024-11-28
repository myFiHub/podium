class UserInfoModel {
  late String id;
  late String fullName;
  late String email;
  late String avatar;
  late String localWalletAddress;
  late List<String> following;
  String? lowercasename;
  late String savedInternalWalletAddress;
  late int numberOfFollowers;
  bool isOver18 = false;
  String referrer = '';
  String? loginType;
  String? loginTypeIdentifier;

  static String idKey = 'id';
  static String fullNameKey = 'fullName';
  static String emailKey = 'email';
  static String avatarUrlKey = 'avatar';
  static String localWalletAddressKey = 'localWalletAddress';
  static String followingKey = 'following';
  static String numberOfFollowersKey = 'numberOfFollowers';
  static String lowercasenameKey = 'lowercasename';
  static String isOver18Key = 'isOver18';
  static String loginTypeKey = 'loginType';
  static String loginTypeIdentifierKey = 'loginTypeIdentifier';
  static String savedInternalWalletAddressKey = 'savedInternalWalletAddress';
  static String referrerKey = 'referrer';

  UserInfoModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.localWalletAddress,
    required this.following,
    required this.numberOfFollowers,
    required this.savedInternalWalletAddress,
    this.lowercasename,
    this.isOver18 = false,
    this.loginType,
    this.loginTypeIdentifier,
    this.referrer = '',
  });

  String get defaultWalletAddress {
    final walletAddress = localWalletAddress;
    if (walletAddress.isEmpty) {
      if (savedInternalWalletAddress.isEmpty) {
        return '';
      }
      return savedInternalWalletAddress;
    }
    return walletAddress;
  }

  String get internalWalletAddress {
    final firstInternalAddress = savedInternalWalletAddress;
    return firstInternalAddress;
  }

  UserInfoModel.fromJson(Map<String, dynamic> json) {
    id = json[idKey];
    fullName = json[fullNameKey];
    email = json[emailKey];
    avatar = json[avatarUrlKey];
    localWalletAddress = json[localWalletAddressKey] ?? '';
    following = json[followingKey] ?? [];
    numberOfFollowers = json[numberOfFollowersKey] ?? 0;
    lowercasename = json[lowercasenameKey] ?? fullName.toLowerCase();
    isOver18 = json[isOver18Key] ?? false;
    loginType = json[loginTypeKey];
    referrer = json[referrerKey] ?? '';
    savedInternalWalletAddress = json[savedInternalWalletAddressKey];
    loginTypeIdentifier = json[loginTypeIdentifierKey];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[idKey] = id;
    data[fullNameKey] = fullName;
    data[emailKey] = email;
    data[avatarUrlKey] = avatar;
    data[localWalletAddressKey] = localWalletAddress;
    data[savedInternalWalletAddressKey] = savedInternalWalletAddress;
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
    String? localWalletAddress,
    List<String>? following,
    int? numberOfFollowers,
    String? lowercasename,
    String? savedInternalWalletAddress,
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
      localWalletAddress: localWalletAddress ?? this.localWalletAddress,
      following: following ?? this.following,
      numberOfFollowers: numberOfFollowers ?? this.numberOfFollowers,
      lowercasename: lowercasename ?? this.lowercasename,
      isOver18: isOver18 ?? this.isOver18,
      loginType: loginType ?? this.loginType,
      savedInternalWalletAddress:
          savedInternalWalletAddress ?? this.savedInternalWalletAddress,
      loginTypeIdentifier: loginTypeIdentifier ?? this.loginTypeIdentifier,
      referrer: referrer ?? this.referrer,
    );
  }
}
