import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/follow/follower.dart';
import 'package:podium/providers/api/podium/models/metadata/metadata.dart';
import 'package:podium/providers/api/podium/models/notifications/notificationModel.dart';
import 'package:podium/providers/api/podium/models/outposts/createOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/inviteRequestModel.dart';
import 'package:podium/providers/api/podium/models/outposts/liveData.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/outposts/rejectInvitationRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/updateOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/pass/buy_sell_request.dart';
import 'package:podium/providers/api/podium/models/pass/buyer.dart';
import 'package:podium/providers/api/podium/models/tag/tag.dart';
import 'package:podium/providers/api/podium/models/users/follow_unfollow_request.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/logger.dart';

class PodiumApi {
  final _baseUrl = Env.podimBackendBaseUrl;
  final Dio dio;
  String? _token;

  Map<String, String> get _headers => _token != null
      ? {...defaultHeaders, 'Authorization': 'Bearer $_token'}
      : defaultHeaders;

  PodiumApi(this.dio);

  Future<bool> connectToWebSocket() async {
    final globalController = Get.find<GlobalController>();
    return await globalController.initializeWebSocket(token: _token!);
  }

  Future<PodiumAppMetadata> appMetadata() async {
    try {
      final config = await dio.get('$_baseUrl/configurations/app-settings',
          options: Options(headers: _headers));
      return PodiumAppMetadata.fromJson(config.data['data']);
    } catch (e) {
      return const PodiumAppMetadata(
        force_update: true,
        movement_aptos_metadata: Movement_Aptos_Metadata(
          chain_id: "126",
          cheer_boo_address:
              "0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa",
          name: "Movement Mainnet",
          podium_protocol_address:
              "0xd2f0d0cf38a4c64620f8e9fcba104e0dd88f8d82963bef4ad57686c3ee9ed7aa",
          rpc_url: "https://mainnet.movementnetwork.xyz/v1",
        ),
        referrals_enabled: true,
        va: "https://outposts.myfihub.com",
        version: "1.1.7",
        version_check: true,
      );
    }
  }

  Future<(UserModel?, String?, int?)> login({
    required LoginRequest request,
    required AdditionalDataForLogin additionalData,
  }) async {
    LoginRequest loginRequest = request;
    loginRequest.referrer_user_uuid =
        loginRequest.referrer_user_uuid?.replaceAll('/', '');
    try {
      final response =
          await dio.post('$_baseUrl/auth/login', data: loginRequest.toJson());
      if (response.statusCode == 200) {
        _token = response.data['data']['token'];
        await connectToWebSocket();
        final myUserData = await getMyUserData(
          additionalData: additionalData,
        );

        return (myUserData, null, response.statusCode);
      } else {
        return (null, 'User not found', response.statusCode);
      }
    } on DioException catch (e) {
      l.d('e: ${e.response}');
      final String? message = e.response?.data['message'];
      return (null, message, e.response?.statusCode);
    } catch (e) {
      return (null, 'User not found', null);
    }
  }

  Future<UserModel?> getMyUserData({
    required AdditionalDataForLogin additionalData,
  }) async {
    try {
      final response = await dio.get(
        '$_baseUrl/users/profile',
        options: Options(headers: _headers),
      );
      UserModel myUser = UserModel.fromJson(response.data['data']);
      final Map<String, dynamic> patchJson = {};
      final fieldsToUpdate = {
        'email': (myUser.email, additionalData.email),
        'name': (myUser.name, additionalData.name),
        'image': (myUser.image, additionalData.image),
        'login_type': (myUser.login_type, additionalData.loginType),
      };

      patchJson.addAll(Map.fromEntries(fieldsToUpdate.entries
          .where((entry) => entry.value.$1 == null && entry.value.$2 != null)
          .map((entry) => MapEntry(entry.key, entry.value.$2!))));
      if (patchJson.isNotEmpty) {
        final updatedUser = await updateMyUserData(patchJson);
        if (updatedUser != null) {
          myUser = updatedUser;
        }
      }

      return myUser;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, UserModel>> searchUserByName({
    required String name,
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/users/search',
          queryParameters: {
            'text': name,
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      final usersList = (response.data['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
      final Map<String, UserModel> usersMap = {};
      usersList.forEach((user) {
        usersMap[user.uuid] = user;
      });
      return usersMap;
    } catch (e) {
      l.e(e);
      return {};
    }
  }

  Future<int> getNumberOfOnlineMembers(String outpostId) async {
    try {
      final response = await dio.get('$_baseUrl/outposts/online-members-count',
          queryParameters: {'uuid': outpostId},
          options: Options(headers: _headers));
      return response.data['data']['count'];
    } catch (e) {
      l.e(e);
      return 0;
    }
  }

  Future<bool> setCreatorJoinedToTrue(String outpostId) async {
    try {
      final response = await dio.post('$_baseUrl/outposts/creator-joined',
          data: {'uuid': outpostId}, options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<UserModel?> updateMyUserData(
    Map<String, dynamic> patchJson,
  ) async {
    final response = await dio.post('$_baseUrl/users/update-profile',
        data: patchJson, options: Options(headers: _headers));
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel?> getUserData(String id) async {
    try {
      id = id.replaceAll('/', '');
      final response = await dio.get('$_baseUrl/users/detail?uuid=$id',
          options: Options(headers: _headers));
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getUserByAptosAddress(String address) async {
    try {
      final response = await dio.get('$_baseUrl/users/detail/by-aptos-address',
          queryParameters: {'aptos_address': address},
          options: Options(headers: _headers));
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    try {
      final List<Future<UserModel?>> callArray = [];
      for (var id in ids) {
        callArray.add(getUserData(id));
      }
      final List<UserModel?> response = await Future.wait(callArray);
      return response.whereType<UserModel>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserModel>> getUserByAptosAddresses(
      List<String> addresses) async {
    try {
      final callArray =
          addresses.map((address) => getUserByAptosAddress(address));
      final List<UserModel?> response = await Future.wait(callArray);
      return response.whereType<UserModel>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> followUnfollow(String uuid, FollowUnfollowAction action) async {
    try {
      await dio.post('$_baseUrl/users/follow',
          data: FollowUnfollowRequest(uuid: uuid, action: action).toJson(),
          options: Options(headers: _headers));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<FollowerModel>> getFollowersOfUser({
    required String uuid,
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/users/followers',
          queryParameters: {
            'uuid': uuid,
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      return (response.data['data'] as List)
          .map((e) => FollowerModel.fromJson(e))
          .toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }

  Future<List<FollowerModel>> getFollowingsOfUser({
    required String uuid,
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/users/followings',
          queryParameters: {
            'uuid': uuid,
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      return (response.data['data'] as List)
          .map((e) => FollowerModel.fromJson(e))
          .toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }

  Future<List<FollowerModel>> getMyFollowers({
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/users/followers',
          queryParameters: {
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      return (response.data['data'] as List)
          .map((e) => FollowerModel.fromJson(e))
          .toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }

  Future<List<FollowerModel>> getMyFollowings({
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/users/followings',
          queryParameters: {
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      return (response.data['data'] as List)
          .map((e) => FollowerModel.fromJson(e))
          .toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }

  Future<OutpostModel?> getOutpost(String id) async {
    try {
      id = id.replaceAll('/', '');
      final response = await dio.get('$_baseUrl/outposts/detail?uuid=$id',
          options: Options(headers: _headers));
      return OutpostModel.fromJson(response.data['data']);
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  Future<Map<String, OutpostModel>> searchOutpostByName({
    required String name,
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/outposts/search',
          queryParameters: {'text': name}, options: Options(headers: _headers));
      final outposts = (response.data['data'] as List)
          .map((e) => OutpostModel.fromJson(e))
          .toList();
      final Map<String, OutpostModel> outpostsMap = {};
      outposts.forEach((outpost) {
        outpostsMap[outpost.uuid] = outpost;
      });
      return outpostsMap;
    } catch (e) {
      l.e(e);
      return {};
    }
  }

  Future<Map<String, TagModel>> searchTag({
    required String tagName,
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/tags/search',
          queryParameters: {'text': tagName},
          options: Options(headers: _headers));
      final tags = (response.data['data'] as List)
          .map((e) => TagModel.fromJson(e))
          .toList();
      return Map.fromEntries(
          tags.map((tag) => MapEntry(tag.id.toString(), tag)));
    } catch (e) {
      l.e(e);
      return {};
    }
  }

  Future<bool> updateOutpost({
    required UpdateOutpostRequest request,
  }) async {
    try {
      final response = await dio.post('$_baseUrl/outposts/update',
          data: request.toJson(), options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<OutpostModel?> createOutpost(CreateOutpostRequest request) async {
    try {
      final response = await dio.post('$_baseUrl/outposts/create',
          data: request.toJson(), options: Options(headers: _headers));
      return OutpostModel.fromJson(response.data['data']);
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  Future<List<OutpostModel>> getOutposts({
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/outposts',
          queryParameters: {
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      return (response.data['data'] as List)
          .map((e) => OutpostModel.fromJson(e))
          .toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }

  Future<Map<String, OutpostModel>> getOutpostsByTagId({
    required int id,
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/outposts',
          queryParameters: {
            'tag_id': id,
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      final outposts = (response.data['data'] as List)
          .map((e) => OutpostModel.fromJson(e))
          .toList();
      final Map<String, OutpostModel> outpostsMap = {};
      outposts.forEach((outpost) {
        outpostsMap[outpost.uuid] = outpost;
      });
      return outpostsMap;
    } catch (e) {
      l.e(e);
      return {};
    }
  }

  Future<List<OutpostModel>> getMyOutposts({
    bool include_archived = true,
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/outposts/my-outposts',
          queryParameters: {
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
            'include_archived': include_archived,
          },
          options: Options(headers: _headers));
      return (response.data['data'] as List)
          .map((e) => OutpostModel.fromJson(e))
          .toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }

  Future<bool?> toggleOutpostArchive(String id, bool archive) async {
    final response = await dio.post('$_baseUrl/outposts/set-archive',
        data: {'uuid': id, 'archive': archive},
        options: Options(headers: _headers));
    return response.statusCode == 200;
  }

  Future<bool> reportOutpost({
    required String outpostId,
    required List<String> reasons,
  }) async {
    try {
      final response = await dio.post('$_baseUrl/outposts/report',
          data: {'uuid': outpostId, 'reasons': reasons},
          options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<bool> addMeAsMember({
    required String outpostId,
    String? inviterId,
  }) async {
    try {
      final response = await dio.post('$_baseUrl/outposts/add-me-as-member',
          data: {
            'uuid': outpostId,
            if (inviterId != null) 'inviter_uuid': inviterId,
          },
          options: Options(headers: _headers));
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<bool> inviteUserToJoinOutpost(InviteRequestModel request) async {
    try {
      final response = await dio.post('$_baseUrl/outposts/invites/create',
          data: request.toJson(), options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<bool> rejectInvitation(RejectInvitationRequest request) async {
    try {
      final response = await dio.post('$_baseUrl/outposts/invites/reject',
          data: request.toJson(), options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<bool> markNotificationAsRead({required String id}) async {
    try {
      final response = await dio.post('$_baseUrl/notifications/mark-as-read',
          data: {"uuid": id}, options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await dio.delete('$_baseUrl/notifications',
          data: {'uuid': id}, options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<bool> leaveOutpost(String id) async {
    try {
      final response = await dio.post('$_baseUrl/outposts/leave',
          data: {'uuid': id}, options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await dio.get('$_baseUrl/notifications',
          options: Options(headers: _headers));
      return (response.data['data'] as List).map((e) {
        final created_at = e['created_at'];
        final is_read = e['is_read'];
        final message = e['message'];
        final notification_type_str = e['notification_type'];
        final uuid = e['uuid'];

        // Convert string to enum
        NotificationTypes notification_type;
        if (notification_type_str == 'follow') {
          notification_type = NotificationTypes.follow;
        } else if (notification_type_str == 'invite') {
          notification_type = NotificationTypes.invite;
        } else {
          throw Exception('Unknown notification type: $notification_type_str');
        }

        FollowMetadata? followMetadata = null;
        InviteMetadata? inviteMetadata = null;
        if (notification_type == NotificationTypes.follow) {
          followMetadata = FollowMetadata.fromJson(e['metadata']);
        }
        if (notification_type == NotificationTypes.invite) {
          inviteMetadata = InviteMetadata.fromJson(e['metadata']);
        }
        final NotificationModel notification = NotificationModel(
          created_at: created_at,
          is_read: is_read,
          message: message,
          notification_type: notification_type,
          follow_metadata: followMetadata,
          invite_metadata: inviteMetadata,
          uuid: uuid,
        );
        return notification;
      }).toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }

  Future<bool> deactivateAccount() async {
    try {
      final response = await dio.post('$_baseUrl/users/deactivate',
          options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<OutpostLiveData?> getLatestLiveData(
      {required String outpostId}) async {
    try {
      final response = await dio.get('$_baseUrl/outposts/online-data',
          queryParameters: {
            'uuid': outpostId,
          },
          options: Options(headers: _headers));
      return OutpostLiveData.fromJson(response.data['data']);
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  Future<bool> buySellPodiumPass(BuySellPodiumPassRequest request) async {
    try {
      final response = await dio.post('$_baseUrl/podium-passes/trade',
          data: request.toJson(), options: Options(headers: _headers));
      return response.statusCode == 200;
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  Future<List<PodiumPassBuyerModel>> myPodiumPasses({
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/podium-passes/my-passes',
          queryParameters: {
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      return (response.data['data'] as List)
          .map((e) => PodiumPassBuyerModel.fromJson(e))
          .toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }

  Future<List<PodiumPassBuyerModel>> podiumPassBuyers({
    required String uuid,
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/podium-passes/recent-holders',
          queryParameters: {
            'uuid': uuid,
            if (page != null) 'page': page,
            if (page_size != null) 'page_size': page_size,
          },
          options: Options(headers: _headers));
      return (response.data['data'] as List)
          .map((e) => PodiumPassBuyerModel.fromJson(e))
          .toList();
    } catch (e) {
      l.e(e);
      return [];
    }
  }
}
