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
  late FirebaseParticleAuthUserInfo? savedParticleUserInfo;
  late int numberOfFollowers;
  bool isOver18 = false;

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

  UserInfoModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.localWalletAddress,
    required this.following,
    required this.numberOfFollowers,
    this.lowercasename,
    this.localParticleUserInfo,
    this.savedParticleUserInfo,
    this.isOver18 = false,
  });

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
    return data;
  }
}
