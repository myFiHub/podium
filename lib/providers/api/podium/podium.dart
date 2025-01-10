import 'package:dio/dio.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/auth/loginRequest.dart';
import 'package:podium/providers/api/podium/models/auth/loginResponse.dart';
import 'package:podium/providers/api/podium/models/user/myUserDataResponse.dart';
import 'package:podium/providers/api/podium/models/user/userDataResponse.dart';

class PodiumApi {
  final _baseUrl = Env.podimBackendBaseUrl;
  final Dio dio;
  String? _token;
  get _headers => _token != null
      ? {...defaultHeaders, 'Authorization': 'Bearer $_token'}
      : defaultHeaders;

  PodiumApi(this.dio);

  Future<MyUserDataResponse?> login({
    required LoginRequest request,
    String? aptosAddress,
    String? email,
    String? name,
    String? image,
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
        );
        return myUserData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<MyUserDataResponse?> getMyUserData({
    String? aptosAddress,
    String? email,
    String? name,
    String? image,
  }) async {
    try {
      final response = await dio.get('$_baseUrl/users/profile',
          options: Options(headers: _headers));
      MyUserDataResponse myUser =
          MyUserDataResponse.fromJson(response.data['data']);
      final Map<String, dynamic> patchJson = {};
      if (myUser.aptosAddress == null && aptosAddress != null) {
        patchJson['aptosAddress'] = aptosAddress;
      }
      if (myUser.email == null && email != null) {
        patchJson['email'] = email;
      }
      if (myUser.name == null && name != null) {
        patchJson['name'] = name;
      }
      if (myUser.image == null && image != null) {
        patchJson['image'] = image;
      }
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

  Future<MyUserDataResponse?> updateMyUserData(
    Map<String, dynamic> patchJson,
  ) async {
    final response = await dio.patch('$_baseUrl/users/update-profile',
        data: patchJson, options: Options(headers: _headers));
    return MyUserDataResponse.fromJson(response.data['data']);
  }

  Future<UserDataResponse?> getUserData(String id) async {
    try {
      final response = await dio.get('$_baseUrl/users/detail?uuid=$id',
          options: Options(headers: _headers));
      return UserDataResponse.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }
}
