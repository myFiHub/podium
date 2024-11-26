import 'package:particle_base/model/user_info.dart' as ParticleUser;
import "package:podium/models/firebase_particle_user.dart";

class UserInfoModel {
  late String id;
  late String fullName;
  late String email;
  late String avatar;
  late String localWalletAddress;
  late List<String> following;
  String? lowercasename;
  late ParticleUser.UserInfo? localParticleUserInfo;
  late String savedParticleWalletAddress;
  late FirebaseInternalWalletInfo? savedParticleUserInfo;
  late int numberOfFollowers;
  bool isOver18 = false;
  String? loginType;
  String? loginTypeIdentifier;

  static String idKey = 'id';
  static String fullNameKey = 'fullName';
  static String emailKey = 'email';
  static String avatarUrlKey = 'avatar';
  static String localWalletAddressKey = 'localWalletAddress';
  static String followingKey = 'following';
  static String numberOfFollowersKey = 'numberOfFollowers';
  static String localParticleUserInfoKey = 'localParticleUserInfo';
  static String savedParticleUserInfoKey = 'savedParticleUserInfo';
  static String lowercasenameKey = 'lowercasename';
  static String isOver18Key = 'isOver18';
  static String loginTypeKey = 'loginType';
  static String loginTypeIdentifierKey = 'loginTypeIdentifier';
  static String savedParticleWalletAddressKey = 'savedParticleWalletAddress';

  UserInfoModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.localWalletAddress,
    required this.following,
    required this.numberOfFollowers,
    required this.savedParticleWalletAddress,
    this.lowercasename,
    this.localParticleUserInfo,
    this.savedParticleUserInfo,
    this.isOver18 = false,
    this.loginType,
    this.loginTypeIdentifier,
  });

  String get defaultWalletAddress {
    final walletAddress = localWalletAddress;
    if (walletAddress.isEmpty) {
      final firstInternalWalletAddress = savedParticleUserInfo?.wallets.where(
        (w) => w.address.isNotEmpty && w.chain == 'evm_chain',
      );
      if (firstInternalWalletAddress == null ||
          firstInternalWalletAddress.isEmpty) {
        return '';
      }
      return firstInternalWalletAddress.first.address;
    }
    return walletAddress;
  }

  String get internalWalletAddress {
    final firstInternalAddress = savedParticleUserInfo?.wallets
        .where(
          (w) => w.address.isNotEmpty && w.chain == 'evm_chain',
        )
        .toList();
    return firstInternalAddress!.first.address;
  }

  UserInfoModel.fromJson(Map<String, dynamic> json) {
    id = json[idKey];
    fullName = json[fullNameKey];
    email = json[emailKey];
    avatar = json[avatarUrlKey];
    localWalletAddress = json[localWalletAddressKey] ?? '';
    following = json[followingKey] ?? [];
    numberOfFollowers = json[numberOfFollowersKey] ?? 0;
    localParticleUserInfo = json[localParticleUserInfoKey];
    lowercasename = json[lowercasenameKey] ?? fullName.toLowerCase();
    isOver18 = json[isOver18Key] ?? false;
    loginType = json[loginTypeKey];
    savedParticleWalletAddress =
        json[savedParticleWalletAddressKey] ?? internalWalletAddress;
    loginTypeIdentifier = json[loginTypeIdentifierKey];
    savedParticleUserInfo =
        json[savedParticleUserInfoKey] ?? internalWalletAddress;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[idKey] = id;
    data[fullNameKey] = fullName;
    data[emailKey] = email;
    data[avatarUrlKey] = avatar;
    data[localWalletAddressKey] = localWalletAddress;
    if (savedParticleUserInfo != null) {
      data[savedParticleUserInfoKey] = savedParticleUserInfo!.toJson();
    }
    data[followingKey] = following;
    data[numberOfFollowersKey] = numberOfFollowers;
    data[localParticleUserInfoKey] = localParticleUserInfo;
    data[lowercasenameKey] = lowercasename ?? fullName.toLowerCase();
    data[isOver18Key] = isOver18;
    data[loginTypeKey] = loginType;
    data[loginTypeIdentifierKey] = loginTypeIdentifier;
    data[savedParticleWalletAddressKey] = savedParticleWalletAddress;
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
    ParticleUser.UserInfo? localParticleUserInfo,
    String? savedParticleWalletAddress,
    FirebaseInternalWalletInfo? savedParticleUserInfo,
    bool? isOver18,
    String? loginType,
    String? loginTypeIdentifier,
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
      localParticleUserInfo:
          localParticleUserInfo ?? this.localParticleUserInfo,
      savedParticleUserInfo:
          savedParticleUserInfo ?? this.savedParticleUserInfo,
      isOver18: isOver18 ?? this.isOver18,
      loginType: loginType ?? this.loginType,
      savedParticleWalletAddress:
          savedParticleWalletAddress ?? this.savedParticleWalletAddress,
      loginTypeIdentifier: loginTypeIdentifier ?? this.loginTypeIdentifier,
    );
  }
}
