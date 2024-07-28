class FirebaseNotificationModel {
  late String id;
  late String title;
  late String body;
  late String type;
  late String? image;
  late String targetUserId;
  late bool isRead;
  late int timestamp;

  static const String idKey = 'id';
  static const String titleKey = 'title';
  static const String bodyKey = 'body';
  static const String typeKey = 'type';
  static const String imageKey = 'image';
  static const String targetUserIdKey = 'targetUserId';
  static const String isReadKey = 'isRead';
  static const String timestampKey = 'timestamp';

  FirebaseNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.image,
    required this.targetUserId,
    required this.isRead,
    required this.timestamp,
  });

  FirebaseNotificationModel.fromJson(Map<String, dynamic> json) {
    id = json[idKey];
    title = json[titleKey];
    body = json[bodyKey];
    type = json[typeKey];
    image = json[imageKey];
    targetUserId = json[targetUserIdKey];
    isRead = json[isReadKey];
    timestamp = json[timestampKey];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data[idKey] = id;
    data[titleKey] = title;
    data[bodyKey] = body;
    data[typeKey] = type;
    data[imageKey] = image;
    data[targetUserIdKey] = targetUserId;
    data[isReadKey] = isRead;
    data[timestampKey] = timestamp;
    return data;
  }
}

enum NotificationTypes {
  follow,
}
