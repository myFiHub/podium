import 'dart:io';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podium/app/modules/global/utils/permissions.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/logger.dart';

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
}) async {
  int id = alarmId == 0 ? Random().nextInt(1000000) : alarmId;
  final hasNotificationPermission =
      await getPermission(Permission.notification);
  if (!hasNotificationPermission) {
    Get.snackbar('Permission Required',
        'Please enable notifications permission to set reminders');
    return null;
  }

  final alreadtSetAlarm = Alarm.getAlarm(id);
  if (alreadtSetAlarm != null) {
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
              onPressed: () {
                Navigator.pop(Get.context!, null);
              },
              child: Text('No Alarm', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      )
    ],
  ));
  if (alarmMeBefore == null) {
    log.d('alarm not set');
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
      notificationTitle: 'Podium',
      notificationBody: alarmMeBefore == 0
          ? "${eventName} Started"
          : '${eventName} will start in $alarmMeBefore minutes',
      enableNotificationOnKill: Platform.isAndroid,
    );
    await Alarm.set(alarmSettings: alarmSettings);
  }
  return alarmMeBefore;
}
