import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class Web3AuthRedirectedController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() async {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}

addressToUuid(String address) {
  final uuid = const Uuid();
  final uid = uuid.v5(Namespace.url.value, address);
  return uid;
}
