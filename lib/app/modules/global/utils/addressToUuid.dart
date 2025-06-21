import 'package:uuid/uuid.dart';

String stringToUuid(String string) {
  final uuid = const Uuid();
  final uid = uuid.v5(Namespace.url.value, string);
  return uid;
}
