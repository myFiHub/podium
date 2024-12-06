
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:podium/providers/api/models/starsArenaUser.dart';
import 'package:podium/utils/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

Dio dio = Dio();

class HttpApis {
  static String baseUrl = 'https://api.starsarena.com/';
  static configure() {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        // logPrint: log.d,
        enabled: kDebugMode,
        filter: (options, args) {
          // don't print responses with unit8 list data
          return !args.isResponse || !args.hasUint8ListData;
        },
      ),
    );
  }

  static Future<StarsArenaUser?> getUserFromStarsArenaByHandle(
      String handle) async {
    try {
      final String url = baseUrl + 'user/handle?handle=$handle';
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
      log.e(e);
      return null;
    }
  }

  static Future<StarsArenaUser?> getUserFromStarsArenaById(
      String handle) async {
    try {
      final String url = baseUrl + 'user/id?userId=$handle';
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
      log.e(e);
      return null;
    }
  }
}
