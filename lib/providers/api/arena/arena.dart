import 'package:dio/dio.dart';
import 'package:podium/providers/api/models/arena/user.dart';
import 'package:podium/utils/logger.dart';

class ArenaApi {
  final Dio dio;
  ArenaApi(this.dio);

  static const String _starsArenaBaseUrl = "https://api.starsarena.com";

  Future<StarsArenaUser?> getUserFromStarsArenaByHandle(String handle) async {
    try {
      final String url = _starsArenaBaseUrl + '/user/handle?handle=$handle';
      // request with dio
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final userInformation = StarsArenaUser.fromJson(response.data['user']);
        return userInformation;
      } else {
        // Failed to get the response
        print('Failed to fetch data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  Future<StarsArenaUser?> getUserFromStarsArenaById(String handle) async {
    try {
      final String url = _starsArenaBaseUrl + '/user/id?userId=$handle';
      // request with dio
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final userInformation = StarsArenaUser.fromJson(response.data['user']);
        return userInformation;
      } else {
        // Failed to get the response
        print('Failed to fetch data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      l.e(e);
      return null;
    }
  }
}
