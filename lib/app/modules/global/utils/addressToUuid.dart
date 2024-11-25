import 'package:uuid/uuid.dart';

addressToUuid(String address) {
  final uuid = Uuid();
  final uid = uuid.v5(Namespace.url.value, address);
  return uid;
}