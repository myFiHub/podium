import 'package:dio/dio.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';

class PodiumApi {
  final _baseUrl = Env.podimBackendBaseUrl;
  final Dio dio;
  String? _token;
  get _headers => _token != null
      ? {...defaultHeaders, 'Authorization': 'Bearer $_token'}
      : defaultHeaders;

  PodiumApi(this.dio);

  Future<UserModel?> login({
    required LoginRequest request,
    String? aptosAddress,
    String? email,
    String? name,
    String? image,
    String? loginType,
    String? loginTypeIdentifier,
    String? refererUserUuid,
  }) async {
    try {
      final response =
          await dio.post('$_baseUrl/auth/login', data: request.toJson());
      if (response.statusCode == 200) {
        _token = response.data['data']['token'];
        final myUserData = await getMyUserData(
          aptosAddress: aptosAddress,
          email: email,
          name: name,
          image: image,
          loginType: loginType,
          loginTypeIdentifier: loginTypeIdentifier,
          refererUserUuid: refererUserUuid,
        );
        return myUserData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getMyUserData({
    String? aptosAddress,
    String? email,
    String? name,
    String? image,
    String? loginType,
    String? loginTypeIdentifier,
    String? refererUserUuid,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/users/profile',
          options: Options(headers: _headers));
      UserModel myUser = UserModel.fromJson(response.data['data']);
      final Map<String, dynamic> patchJson = {};
      final fieldsToUpdate = {
        'aptos_address': (myUser.aptos_address, aptosAddress),
        'email': (myUser.email, email),
        'name': (myUser.name, name),
        'image': (myUser.image, image),
        'login_type': (myUser.login_type, loginType),
        'login_type_identifier': (
          myUser.login_type_identifier,
          loginTypeIdentifier
        ),
        'referer_user_uuid': (myUser.referer_user_uuid, refererUserUuid),
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

  Future<UserModel?> updateMyUserData(
    Map<String, dynamic> patchJson,
  ) async {
    final response = await dio.patch('$_baseUrl/users/update-profile',
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

  Future<OutpostModel?> getOutpost(String id) async {
    try {
      final response = await dio.get('$_baseUrl/outposts/detail?uuid=$id',
          options: Options(headers: _headers));
      return OutpostModel.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }
}
