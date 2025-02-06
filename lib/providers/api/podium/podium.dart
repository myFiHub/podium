import 'package:dio/dio.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/createOutpostRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/follow_unfollow_request.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/utils/logger.dart';

class PodiumApi {
  final _baseUrl = Env.podimBackendBaseUrl;
  final Dio dio;
  String? _token;
  get _headers => _token != null
      ? {...defaultHeaders, 'Authorization': 'Bearer $_token'}
      : defaultHeaders;

  PodiumApi(this.dio);

  Future<(UserModel?, String?)> login({
    required LoginRequest request,
    required AdditionalDataForLogin additionalData,
  }) async {
    try {
      final response =
          await dio.post('$_baseUrl/auth/login', data: request.toJson());
      if (response.statusCode == 200) {
        _token = response.data['data']['token'];
        final myUserData = await getMyUserData(
          additionalData: additionalData,
        );

        return (myUserData, null);
      } else {
        return (null, 'User not found');
      }
    } on DioException catch (e) {
      final String? message = e.response?.data['message'];
      return (null, message);
    } catch (e) {
      return (null, 'User not found');
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

  Future<List<UserModel>> searchUserByName({
    required String name,
    int? page,
    int? page_size,
  }) async {
    final response = await dio.get('$_baseUrl/users/search',
        queryParameters: {
          'text': name,
          if (page != null) 'page': page,
          if (page_size != null) 'page_size': page_size,
        },
        options: Options(headers: _headers));
    return (response.data['data'] as List)
        .map((e) => UserModel.fromJson(e))
        .toList();
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
      final response = await dio.get('$_baseUrl/users/detail?uuid=$id',
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

  Future<OutpostModel?> getOutpost(String id) async {
    try {
      final response = await dio.get('$_baseUrl/outposts/detail?uuid=$id',
          options: Options(headers: _headers));
      return OutpostModel.fromJson(response.data['data']);
    } catch (e) {
      return null;
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

  Future<List<OutpostModel>> getMyOutposts({
    int? page,
    int? page_size,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/outposts/my-outposts',
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

  Future<bool?> toggleOutpostArchive(String id, bool archive) async {
    final response = await dio.post('$_baseUrl/outposts/set-archive',
        data: {'uuid': id, 'archive': archive},
        options: Options(headers: _headers));
    return response.statusCode == 200;
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
}
