import 'dart:io';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/app/modules/global/utils/permissions.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/outposts/setReminder.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

Future<bool> createCalendarEventForScheduledGroup({
  String? eventUrl,
  required int scheduledFor,
  required String title,
  String? subject,
}) async {
  final Event event = Event(
    title: title,
    description: subject,
    location: 'Podium app',
    startDate: DateTime.fromMillisecondsSinceEpoch(scheduledFor),
    // 30min from start
    endDate: DateTime.fromMillisecondsSinceEpoch(scheduledFor + 30 * 60 * 1000),
    iosParams: IOSParams(
      reminder: const Duration(
          hours:
              1 /* Ex. hours:1 */), // on iOS, you can set alarm notification after your event.
      url: eventUrl, // on iOS, you can set url to your event.
    ),
    androidParams: const AndroidParams(
      emailInvites: [], // on Android, you can add invite emails to your event.
    ),
  );
  if (Platform.isAndroid) {
    return await Add2Calendar.addEvent2Cal(event);
  }
  Add2Calendar.addEvent2Cal(event);
  return true;
}

List<Map<String, Object>> defaultTimeList({required int endsAt}) {
  List<Map<String, Object>> timesList = [
    {'time': 30, 'text': '30 minutes before'},
    {'time': 10, 'text': '10 minutes before'},
    {'time': 5, 'text': '5 minutes before'},
    {"time": 0, "text": "when Event starts"},
  ];

  final numberOfMinoutesToEvent =
      (endsAt - DateTime.now().millisecondsSinceEpoch) ~/ 60000;
  final filteredTimes = timesList
      .where((element) => (element['time'] as int) <= numberOfMinoutesToEvent)
      .toList();
  return filteredTimes;
}

Future<bool> isReminderAlreadySet(OutpostModel outpost) async {
  final isSet = outpost.reminder_offset_minutes != null &&
      outpost.reminder_offset_minutes! > 0;
  return isSet;
}

Future<int?> setReminder({
  required String uuid,
  List<Map<String, Object>>? timesList,
  required int scheduledFor,
  String? eventUrl,
}) async {
  if (timesList == null) {
    timesList = defaultTimeList(endsAt: scheduledFor);
  }
  final hasNotificationPermission =
      await getPermission(Permission.notification);
  if (!hasNotificationPermission) {
    Toast.error(
      message: 'Please enable notifications permission to set reminders',
    );
    return null;
  }

  final outpost = await HttpApis.podium.getOutpost(uuid);
  if (outpost == null) {
    Toast.error(
      message: 'Outpost not found',
    );
    return null;
  }

  final int? alarmMeBefore = await Get.dialog<int>(AlertDialog(
    backgroundColor: ColorName.pageBackground,
    title: const Text('Set a Reminder?'),
    content: const Text('Do you want Podium to remind you for this event?'),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < timesList.length; i++)
              TextButton(
                onPressed: () {
                  Navigator.pop(Get.context!, timesList![i]['time']);
                },
                child: Text(timesList[i]['text'] as String,
                    style: TextStyle(color: Colors.red[i * 100])),
              ),
            TextButton(
              onPressed: () async {
                await createCalendarEventForScheduledGroup(
                  eventUrl: eventUrl,
                  scheduledFor: scheduledFor,
                  title: outpost.name,
                  subject: outpost.subject,
                );
                Navigator.pop<int>(Get.context!, -1);
              },
              child: Text(
                  Platform.isAndroid
                      ? 'use my calendar instead'
                      : 'set reminder on calendar',
                  style: TextStyle(color: Colors.green[400])),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(Get.context!, -2);
              },
              child: const Text('NO REMINDER!',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      )
    ],
  ));
  // -2 means remove reminder
  if (alarmMeBefore == -2) {
    if (outpost.reminder_offset_minutes != null) {
      final request = SetOrRemoveReminderRequest(
        uuid: uuid,
      );
      final success = await HttpApis.podium.setOrRemoveReminder(request);
      if (success) {
        Toast.success(message: 'Reminder removed');
        final updatedOutpost = outpost.copyWith.reminder_offset_minutes(null);
        final OutpostsController outpostsController = Get.find();
        outpostsController.updateOutpost_local(updatedOutpost);
      } else {
        Toast.error(message: 'Failed to remove reminder');
      }
    }
  }
  // -1 means I might use my calendar instead. null means no reminder
  else if (alarmMeBefore == null || alarmMeBefore < 0) {
    l.d(' reminder not set');
  } else {
    final request = SetOrRemoveReminderRequest(
      uuid: uuid,
      reminder_offset_minutes: alarmMeBefore,
    );
    final isSet = await HttpApis.podium.setOrRemoveReminder(request);
    if (isSet) {
      Toast.success(
        message:
            'You will be reminded ${alarmMeBefore == 0 ? "when Event is started" : "${alarmMeBefore} minutes before the event"}',
      );
      final updatedOutpost =
          outpost.copyWith.reminder_offset_minutes(alarmMeBefore);
      final OutpostsController outpostsController = Get.find();
      outpostsController.updateOutpost_local(updatedOutpost);
    } else {
      Toast.error(
        message: 'Failed to set reminder',
      );
    }
  }
  return alarmMeBefore;
}
