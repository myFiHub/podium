import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:podium/providers/api/arena/arena.dart';
import 'package:podium/providers/api/luma/luma.dart';
import 'package:podium/providers/api/podium/podium.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

const defaultHeaders = {
  'accept': 'application/json',
  'content-type': 'application/json',
};

final Dio dio = Dio();

class HttpApis {
  static final HttpApis _instance = HttpApis._internal();
  factory HttpApis() => _instance;
  HttpApis._internal() {}

  static LumaApi lumaApi = LumaApi(dio);
  static ArenaApi arenaApi = ArenaApi(dio);
  static PodiumApi podium = PodiumApi(dio);

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
}
