import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/providers/api/podium/models/follow/follower.dart';
import 'package:podium/providers/api/podium/models/pass/buy_sell_request.dart';
import 'package:podium/providers/api/podium/models/pass/buyer.dart';
import 'package:podium/providers/api/podium/models/users/follow_unfollow_request.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/providers/api/podium/podium.dart';

/// Profiles, follows and Podium passes.
class UserRepository {
  UserRepository(this._api);

  final PodiumApi _api;

  /// Fills empty profile fields from [additionalData] (e.g. social login).
  Future<UserModel?> getMyUserData({
    AdditionalDataForLogin? additionalData,
  }) =>
      _api.getMyUserData(
        additionalData: additionalData ?? AdditionalDataForLogin(),
      );

  Future<UserModel?> updateMyUserData(Map<String, dynamic> patchJson) =>
      _api.updateMyUserData(patchJson);

  Future<UserModel?> getUserData(String id) => _api.getUserData(id);

  Future<List<UserModel>> getUsersByIds(List<String> ids) =>
      _api.getUsersByIds(ids);

  Future<List<UserModel>> getUserByAptosAddresses(List<String> addresses) =>
      _api.getUserByAptosAddresses(addresses);

  Future<Map<String, UserModel>> searchUserByName({required String name}) =>
      _api.searchUserByName(name: name);

  Future<bool> followUnfollow(String uuid, FollowUnfollowAction action) =>
      _api.followUnfollow(uuid, action);

  Future<List<FollowerModel>> getFollowersOfUser({required String uuid}) =>
      _api.getFollowersOfUser(uuid: uuid);

  Future<List<FollowerModel>> getFollowingsOfUser({required String uuid}) =>
      _api.getFollowingsOfUser(uuid: uuid);

  Future<List<PodiumPassBuyerModel>> podiumPassBuyers({
    required String uuid,
    int? page,
    int? page_size,
  }) =>
      _api.podiumPassBuyers(uuid: uuid, page: page, page_size: page_size);

  Future<bool> buySellPodiumPass(BuySellPodiumPassRequest request) =>
      _api.buySellPodiumPass(request);
}
