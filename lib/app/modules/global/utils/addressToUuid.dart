import 'package:uuid/uuid.dart';

String stringToUuid(String string) {
  const uuid = Uuid();
  final uid = uuid.v5(Namespace.url.value, string);
  return uid;
}
