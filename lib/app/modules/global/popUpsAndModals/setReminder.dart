import 'dart:io';
import 'dart:math';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/global/utils/permissions.dart';
import 'package:podium/gen/assets.gen.dart';
import 'package:podium/gen/colors.gen.dart';
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
      reminder: Duration(
          hours:
              1 /* Ex. hours:1 */), // on iOS, you can set alarm notification after your event.
      url: eventUrl, // on iOS, you can set url to your event.
    ),
    androidParams: AndroidParams(
      emailInvites: [], // on Android, you can add invite emails to your event.
    ),
  );
  final added = await Add2Calendar.addEvent2Cal(event);
  return added;
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

bool isReminderAlreadySet(int alarmId) {
  final alreadtSetAlarm = Alarm.getAlarm(alarmId);
  if (alreadtSetAlarm != null) {
    return true;
  }
  return false;
}

DateTime? getReminderTime(int alarmId) {
  final alreadtSetAlarm = isReminderAlreadySet(alarmId);
  if (alreadtSetAlarm) {
    final alarm = Alarm.getAlarm(alarmId);
    return alarm!.dateTime;
  }
  return null;
}

Future<int?> setReminder({
  required int alarmId,
  List<Map<String, Object>> timesList = const [
    {'time': 30, 'text': '30 minutes before'},
    {'time': 10, 'text': '10 minutes before'},
    {'time': 5, 'text': '5 minutes before'},
    {"time": 0, "text": "when Event starts"},
  ],
  required int scheduledFor,
  required String eventName,
  String? subject,
  String? eventUrl,
}) async {
  int id = alarmId == 0 ? Random().nextInt(1000000) : alarmId;
  final hasNotificationPermission =
      await getPermission(Permission.notification);
  if (!hasNotificationPermission) {
    Toast.error(
      message: 'Please enable notifications permission to set reminders',
    );
    return null;
  }

  final alreadtSetAlarm = isReminderAlreadySet(alarmId);
  if (alreadtSetAlarm) {
    Alarm.stop(id);
  }

  final int? alarmMeBefore = await Get.dialog<int>(AlertDialog(
    backgroundColor: ColorName.pageBackground,
    title: Text('Set an Alarm?'),
    content: Text('Do you want Podium to remind you for this event?'),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < timesList.length; i++)
              TextButton(
                onPressed: () {
                  Navigator.pop(Get.context!, timesList[i]['time']);
                },
                child: Text(timesList[i]['text'] as String,
                    style: TextStyle(color: Colors.red[i * 100])),
              ),
            TextButton(
              onPressed: () async {
                await createCalendarEventForScheduledGroup(
                  eventUrl: eventUrl,
                  scheduledFor: scheduledFor,
                  title: eventName,
                  subject: subject,
                );

                Navigator.pop(Get.context!, -1);
              },
              child: Text('use my calendar instead',
                  style: TextStyle(color: Colors.green[400])),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(Get.context!, -2);
              },
              child: Text('NO REMINDER!', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      )
    ],
  ));
  if (alarmMeBefore == null || alarmMeBefore < 0) {
    log.d(' local alarm not set');
  } else {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: DateTime.fromMillisecondsSinceEpoch(scheduledFor)
          .subtract(Duration(minutes: alarmMeBefore)),
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0,
      notificationSettings: NotificationSettings(
        title: 'Podium',
        body: alarmMeBefore == 0
            ? "${eventName} Started"
            : '${eventName} will start in $alarmMeBefore minutes',
        icon: Assets.images.logo.path,
        stopButton: 'Stop',
      ),
    );
    await Alarm.set(alarmSettings: alarmSettings);
    Toast.success(
      message:
          'You will be reminded ${alarmMeBefore == 0 ? "when Event is started" : "${alarmMeBefore} minutes before the event"}',
    );
  }
  return alarmMeBefore;
}
