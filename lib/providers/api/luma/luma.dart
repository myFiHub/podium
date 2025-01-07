import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:podium/env.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/models/luma/addGuest.dart';
import 'package:podium/providers/api/models/luma/addHost.dart';
import 'package:podium/providers/api/models/luma/createEvent.dart';
import 'package:podium/providers/api/models/luma/eventModel.dart';
import 'package:podium/providers/api/models/luma/guest.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

final lumaApiOptions = Options(
  headers: {
    'x-luma-api-key': Env.lumaApiKey,
    ...defaultHeaders,
  },
);

class LumaApi {
  final Dio dio;
  LumaApi(this.dio);

  static const String _lumaBaseUrl = "https://api.lu.ma";

  Future<Luma_EventModel?> createEvent({
    required Luma_CreateEvent event,
  }) async {
    try {
      if (event.timezone == null) {
        final currentTimeZone = await FlutterTimezone.getLocalTimezone();
        event.timezone = currentTimeZone;
      }
      if (event.end_at == null) {
        final currentTime = DateTime.now();
        final endTime = currentTime.add(const Duration(hours: 1));
        event.end_at = endTime.toIso8601String();
      }
    } catch (e) {
      l.e(e);
      Toast.error(title: 'Error', message: 'Error getting timezone');
      return null;
    }
    final response = await dio.post(
      _lumaBaseUrl + '/public/v1/event/create',
      data: event.toJson(),
      options: lumaApiOptions,
    );
    if (response.statusCode == 200) {
      final id = response.data['api_id'];
      if (id != null) {
        final event = await getEvent(
          eventId: id,
        );
        return event;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  Future<Luma_EventModel?> getEvent({required String eventId}) async {
    try {
      final response = await dio.get(
        _lumaBaseUrl + '/public/v1/event/get?api_id=$eventId',
        options: lumaApiOptions,
      );
      if (response.statusCode == 200) {
        final jsonBody = response.data;
        final event = Luma_EventModel.fromJson(jsonBody);
        return event;
      } else {
        return null;
      }
    } catch (e) {
      l.e(e);
      return null;
    }
  }

  Future<List<GuestDataModel>> getGuests({required String eventId}) async {
    final response = await dio.get(
      _lumaBaseUrl + '/public/v1/event/get-guests?event_api_id=$eventId',
      options: lumaApiOptions,
    );
    if (response.statusCode == 200) {
      final jsonBody = response.data;
      final array = jsonBody['entries'] as List<dynamic>;
      final quests = array.map((e) => GuestDataModel.fromJson(e)).toList();
      return quests;
    } else {
      return [];
    }
  }

  Future<bool?> addGuests({
    required List<AddGuestModel> guests,
    required String eventId,
  }) async {
    try {
      final response = await dio.post(
        _lumaBaseUrl + '/public/v1/event/add-guests',
        data: {
          'guests': guests.map((e) => e.toJson()).toList(),
          'event_api_id': eventId,
        },
        options: lumaApiOptions,
      );
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

  Future<bool?> sendInvite({
    required List<AddGuestModel> guests,
    required String eventId,
  }) async {
    final response = await dio.post(
      _lumaBaseUrl + '/public/v1/event/send-invite',
      data: {
        'guests': guests.map((e) => e.toJson()).toList(),
        'event_api_id': eventId,
      },
      options: lumaApiOptions,
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool?> addHost({
    required AddHostModel host,
  }) async {
    try {
      final response = await dio.post(
        _lumaBaseUrl + '/public/v1/event/add-host',
        data: host.toJson(),
        options: lumaApiOptions,
      );
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
}
