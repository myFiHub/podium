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
import 'package:alarm/model/volume_settings.dart';

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

Future<bool> isReminderAlreadySet(int alarmId) async {
  final alreadySetAlarm = await Alarm.getAlarm(alarmId);
  return alreadySetAlarm != null;
}

Future<DateTime?> getReminderTime(int alarmId) async {
  final alreadtSetAlarm = await isReminderAlreadySet(alarmId);
  if (alreadtSetAlarm) {
    final alarm = await Alarm.getAlarm(alarmId);
    if (alarm != null) return alarm.dateTime;
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

  final alreadtSetAlarm = await isReminderAlreadySet(alarmId);
  if (alreadtSetAlarm) {
    Alarm.stop(id);
  }

  final int? alarmMeBefore = await Get.dialog<int>(AlertDialog(
    backgroundColor: ColorName.pageBackground,
    title: const Text('Set an Alarm?'),
    content: const Text('Do you want Podium to remind you for this event?'),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (Platform.isAndroid)
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
  if (alarmMeBefore == null || alarmMeBefore < 0) {
    l.d(' local alarm not set');
  } else {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: DateTime.fromMillisecondsSinceEpoch(scheduledFor)
          .subtract(Duration(minutes: alarmMeBefore)),
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: const Duration(seconds: 3),
      ),
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
