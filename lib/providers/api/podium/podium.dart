import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/api_failure.dart';
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
import 'package:podium/providers/api/podium/models/outposts/setReminder.dart';
import 'package:podium/providers/api/podium/models/outposts/updateOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/pass/buy_sell_request.dart';
import 'package:podium/providers/api/podium/models/pass/buyer.dart';
import 'package:podium/providers/api/podium/models/tag/tag.dart';
import 'package:podium/providers/api/podium/models/users/connect_new_account_request.dart';
import 'package:podium/providers/api/podium/models/users/follow_unfollow_request.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/storage.dart';

typedef _FromJson<T> = T Function(Map<String, dynamic> json);

class PodiumApi {
  final _baseUrl = Env.podimBackendBaseUrl;
  final Dio dio;
  String? _token;

  Map<String, String> get _headers => _token != null
      ? {...defaultHeaders, 'Authorization': 'Bearer $_token'}
      : defaultHeaders;

  Options get _options => Options(headers: _headers);

  PodiumApi(this.dio);

  /// Session token from the last successful [authenticate].
  String? get token => _token;

  /// Surfaces every error as an [ApiFailure], so callers can tell a failed
  /// request from an empty result.
  Future<T> _attempt<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      l.e(e);
      throw ApiFailure(
        _errorMessage(e) ?? 'Network error, please try again',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      l.e(e);
      throw const ApiFailure('Unexpected response from server');
    }
  }

  /// Returns [fallback] instead of throwing, so callers never see network errors.
  Future<T> _guard<T>(Future<T> Function() request, T fallback) async {
    try {
      return await _attempt(request);
    } on ApiFailure {
      return fallback;
    }
  }

  Future<dynamic> _getData(String path, {Map<String, dynamic>? query}) async {
    final response = await dio.get(
      '$_baseUrl$path',
      queryParameters: query,
      options: _options,
    );
    return response.data['data'];
  }

  Future<T?> _getOne<T>(
    String path,
    _FromJson<T> fromJson, {
    Map<String, dynamic>? query,
  }) {
    return _guard<T?>(
      () async => fromJson(await _getData(path, query: query)),
      null,
    );
  }

  /// Throws [ApiFailure].
  Future<List<T>> _fetchList<T>(
    String path,
    _FromJson<T> fromJson, {
    Map<String, dynamic>? query,
  }) {
    return _attempt(() async {
      final data = await _getData(path, query: query) as List;
      return data.map((e) => fromJson(e)).toList();
    });
  }

  Future<List<T>> _getList<T>(
    String path,
    _FromJson<T> fromJson, {
    Map<String, dynamic>? query,
  }) {
    return _guard(() => _fetchList(path, fromJson, query: query), <T>[]);
  }

  Future<Map<String, T>> _getMap<T>(
    String path,
    _FromJson<T> fromJson,
    String Function(T item) keyOf, {
    Map<String, dynamic>? query,
  }) async {
    final items = await _getList(path, fromJson, query: query);
    return {for (final item in items) keyOf(item): item};
  }

  /// Sends a POST (or [method]) and reports whether the server answered 200.
  Future<bool> _send(String path, {Object? data, String method = 'POST'}) {
    return _guard(() async {
      final response = await dio.request(
        '$_baseUrl$path',
        data: data,
        options: _options.copyWith(method: method),
      );
      return response.statusCode == 200;
    }, false);
  }

  Map<String, dynamic> _paging(int? page, int? pageSize) => {
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
      };

  Future<PodiumAppMetadata> appMetadata() async {
    final storage = GetStorage();
    try {
      final data = Map<String, dynamic>.from(
        await _getData('/configurations/app-settings'),
      );
      final metadata = PodiumAppMetadata.fromJson(data);
      storage.write(StorageKeys.lastAppMetadata, data);
      return metadata;
    } catch (e) {
      l.e('app-settings unavailable, using last known settings: $e');
      final cached = storage.read(StorageKeys.lastAppMetadata);
      if (cached is Map) {
        try {
          return PodiumAppMetadata.fromJson(Map<String, dynamic>.from(cached));
        } catch (_) {}
      }
      // An outage must never look like a required update.
      return const PodiumAppMetadata(
        force_update: false,
        movement_aptos_metadata: MovementAptosMetadata(
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
        version: "1.2.6",
        version_check: false,
      );
    }
  }

  /// Exchanges a signed login [request] for a session token. On failure the
  /// token is null and [error] carries the server's message when it sent one.
  Future<({String? token, String? error, int? statusCode})> authenticate(
    LoginRequest request,
  ) async {
    request.referrer_user_uuid =
        request.referrer_user_uuid?.replaceAll('/', '');
    try {
      final response =
          await dio.post('$_baseUrl/auth/login', data: request.toJson());
      if (response.statusCode != 200) {
        return (
          token: null,
          error: 'User not found',
          statusCode: response.statusCode,
        );
      }
      try {
        _token = response.data['data']['token'] as String;
      } catch (e) {
        l.e(e);
        return (
          token: null,
          error: 'Login error, try again in a few minutes',
          statusCode: response.statusCode,
        );
      }
      return (token: _token, error: null, statusCode: response.statusCode);
    } on DioException catch (e) {
      l.d('e: ${e.response}');
      return (
        token: null,
        error: _errorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      l.e(e);
      return (token: null, error: 'User not found', statusCode: null);
    }
  }

  Future<UserModel?> getMyUserData({
    required AdditionalDataForLogin additionalData,
  }) {
    return _guard<UserModel?>(() async {
      UserModel myUser = UserModel.fromJson(await _getData('/users/profile'));
      final fieldsToUpdate = {
        'email': (myUser.email, additionalData.email),
        'name': (myUser.name, additionalData.name),
        'image': (myUser.image, additionalData.image),
      };
      final patchJson = <String, dynamic>{
        for (final entry in fieldsToUpdate.entries)
          if (entry.value.$1 == null && entry.value.$2 != null)
            entry.key: entry.value.$2!,
      };
      if (patchJson.isNotEmpty) {
        final updatedUser = await updateMyUserData(patchJson);
        if (updatedUser != null) {
          myUser = updatedUser;
        }
      }
      return myUser;
    }, null);
  }

  Future<Map<String, UserModel>> searchUserByName({
    required String name,
    int? page,
    int? page_size,
  }) {
    return _getMap(
      '/users/search',
      UserModel.fromJson,
      (user) => user.uuid,
      query: {'text': name, ..._paging(page, page_size)},
    );
  }

  Future<int> getNumberOfOnlineMembers(String outpostId) {
    return _guard(() async {
      final data = await _getData(
        '/outposts/online-members-count',
        query: {'uuid': outpostId},
      );
      return data['count'] as int;
    }, 0);
  }

  Future<bool> setCreatorJoinedToTrue(String outpostId) {
    return _send('/outposts/creator-joined', data: {'uuid': outpostId});
  }

  Future<UserModel?> updateMyUserData(Map<String, dynamic> patchJson) {
    return _guard<UserModel?>(() async {
      final response = await dio.post(
        '$_baseUrl/users/update-profile',
        data: patchJson,
        options: _options,
      );
      return UserModel.fromJson(response.data['data']);
    }, null);
  }

  Future<UserModel?> getUserData(String id) {
    return _getOne(
      '/users/detail',
      UserModel.fromJson,
      query: {'uuid': id.replaceAll('/', '')},
    );
  }

  Future<UserModel?> getUserByAptosAddress(String address) {
    return _getOne(
      '/users/detail/by-aptos-address',
      UserModel.fromJson,
      query: {'aptos_address': address},
    );
  }

  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    final users = await Future.wait(ids.map(getUserData));
    return users.whereType<UserModel>().toList();
  }

  Future<List<UserModel>> getUserByAptosAddresses(
      List<String> addresses) async {
    final users = await Future.wait(addresses.map(getUserByAptosAddress));
    return users.whereType<UserModel>().toList();
  }

  Future<bool> followUnfollow(String uuid, FollowUnfollowAction action) {
    return _guard(() async {
      await dio.post(
        '$_baseUrl/users/follow',
        data: FollowUnfollowRequest(uuid: uuid, action: action).toJson(),
        options: _options,
      );
      return true;
    }, false);
  }

  Future<List<FollowerModel>> getFollowersOfUser({
    required String uuid,
    int? page,
    int? page_size,
  }) {
    return _getList(
      '/users/followers',
      FollowerModel.fromJson,
      query: {'uuid': uuid, ..._paging(page, page_size)},
    );
  }

  Future<List<FollowerModel>> getFollowingsOfUser({
    required String uuid,
    int? page,
    int? page_size,
  }) {
    return _getList(
      '/users/followings',
      FollowerModel.fromJson,
      query: {'uuid': uuid, ..._paging(page, page_size)},
    );
  }

  Future<OutpostModel?> getOutpost(String id) {
    return _getOne(
      '/outposts/detail',
      OutpostModel.fromJson,
      query: {'uuid': id.replaceAll('/', '')},
    );
  }

  Future<Map<String, OutpostModel>> searchOutpostByName({
    required String name,
    int? page,
    int? page_size,
  }) {
    return _getMap(
      '/outposts/search',
      OutpostModel.fromJson,
      (outpost) => outpost.uuid,
      query: {'text': name},
    );
  }

  Future<Map<String, TagModel>> searchTag({
    required String tagName,
    int? page,
    int? page_size,
  }) {
    return _getMap(
      '/tags/search',
      TagModel.fromJson,
      (tag) => tag.id.toString(),
      query: {'text': tagName},
    );
  }

  Future<bool> updateOutpost({required UpdateOutpostRequest request}) {
    return _send('/outposts/update', data: request.toJson());
  }

  Future<OutpostModel?> createOutpost(CreateOutpostRequest request) {
    return _guard<OutpostModel?>(() async {
      final response = await dio.post(
        '$_baseUrl/outposts/create',
        data: request.toJson(),
        options: _options,
      );
      return OutpostModel.fromJson(response.data['data']);
    }, null);
  }

  /// Throws [ApiFailure].
  Future<List<OutpostModel>> getOutposts({int? page, int? page_size}) {
    return _fetchList(
      '/outposts',
      OutpostModel.fromJson,
      query: _paging(page, page_size),
    );
  }

  Future<Map<String, OutpostModel>> getOutpostsByTagId({
    required int id,
    int? page,
    int? page_size,
  }) {
    return _getMap(
      '/outposts',
      OutpostModel.fromJson,
      (outpost) => outpost.uuid,
      query: {'tag_id': id, ..._paging(page, page_size)},
    );
  }

  /// Throws [ApiFailure].
  Future<List<OutpostModel>> getMyOutposts({
    bool include_archived = true,
    int? page,
    int? page_size,
  }) {
    return _fetchList(
      '/outposts/my-outposts',
      OutpostModel.fromJson,
      query: {
        ..._paging(page, page_size),
        'include_archived': include_archived,
      },
    );
  }

  Future<bool> toggleOutpostArchive(String id, bool archive) {
    return _send(
      '/outposts/set-archive',
      data: {'uuid': id, 'archive': archive},
    );
  }

  Future<bool> reportOutpost({
    required String outpostId,
    required List<String> reasons,
  }) {
    return _send(
      '/outposts/report',
      data: {'uuid': outpostId, 'reasons': reasons},
    );
  }

  Future<bool> scoreOutpost({required String outpostId, required int score}) {
    return _send(
      '/outposts/rate',
      data: {'uuid': outpostId, 'rating': score},
    );
  }

  Future<bool> addMeAsMember({required String outpostId, String? inviterId}) {
    return _send('/outposts/add-me-as-member', data: {
      'uuid': outpostId,
      if (inviterId != null) 'inviter_uuid': inviterId,
    });
  }

  Future<bool> inviteUserToJoinOutpost(InviteRequestModel request) {
    return _send('/outposts/invites/create', data: request.toJson());
  }

  Future<bool> rejectInvitation(RejectInvitationRequest request) {
    return _send('/outposts/invites/reject', data: request.toJson());
  }

  Future<bool> markNotificationAsRead({required String id}) {
    return _send('/notifications/mark-as-read', data: {'uuid': id});
  }

  Future<bool> deleteNotification(String id) {
    return _send('/notifications', data: {'uuid': id}, method: 'DELETE');
  }

  Future<bool> leaveOutpost(String id) {
    return _send('/outposts/leave', data: {'uuid': id});
  }

  Future<List<NotificationModel>> getNotifications() {
    return _getList('/notifications', _notificationFromJson);
  }

  Future<bool> deactivateAccount() {
    return _send('/users/deactivate');
  }

  Future<OutpostLiveData?> getLatestLiveData({required String outpostId}) {
    return _getOne(
      '/outposts/online-data',
      OutpostLiveData.fromJson,
      query: {'uuid': outpostId},
    );
  }

  Future<bool> buySellPodiumPass(BuySellPodiumPassRequest request) {
    return _send('/podium-passes/trade', data: request.toJson());
  }

  Future<List<PodiumPassBuyerModel>> podiumPassBuyers({
    required String uuid,
    int? page,
    int? page_size,
  }) {
    return _getList(
      '/podium-passes/recent-holders',
      PodiumPassBuyerModel.fromJson,
      query: {'uuid': uuid, ..._paging(page, page_size)},
    );
  }

  Future<bool> setOrRemoveReminder(SetOrRemoveReminderRequest request) {
    return _send('/outposts/set-reminder', data: request.toJson());
  }

  Future<bool> connectNewAccount(ConnectNewAccountRequest request) {
    return _send('/users/accounts/connect', data: request.toJson());
  }

  Future<bool> setAccountAsPrimary({required String address}) async {
    try {
      final response = await dio.post(
        '$_baseUrl/users/accounts/set-primary',
        data: {'address': address},
        options: _options,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      l.e(e);
      Toast.error(
          message: _errorMessage(e) ?? 'Error setting account as primary');
      return false;
    } catch (e) {
      l.e(e);
      return false;
    }
  }
}

NotificationModel _notificationFromJson(Map<String, dynamic> e) {
  final type = switch (e['notification_type']) {
    'follow' => NotificationTypes.follow,
    'invite' => NotificationTypes.invite,
    final other => throw Exception('Unknown notification type: $other'),
  };
  return NotificationModel(
    created_at: e['created_at'],
    is_read: e['is_read'],
    message: e['message'],
    notification_type: type,
    follow_metadata: type == NotificationTypes.follow
        ? FollowMetadata.fromJson(e['metadata'])
        : null,
    invite_metadata: type == NotificationTypes.invite
        ? InviteMetadata.fromJson(e['metadata'])
        : null,
    uuid: e['uuid'],
  );
}

/// Error bodies are not always JSON (e.g. nginx HTML pages on 502).
String? _errorMessage(DioException e) {
  final data = e.response?.data;
  return data is Map ? data['message'] as String? : null;
}
