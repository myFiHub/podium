import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/utils/storage.dart';

/// Server capabilities the app can't assume, so a new app keeps working
/// against a server that hasn't been updated yet.
class ServerFeatures extends GetxService {
  final _storage = GetStorage();

  /// Discovery rails, the host dashboard and outpost analytics. They shipped
  /// in the same server release, so one check covers all of them.
  late final discovery =
      (_storage.read<bool>(StorageKeys.serverHasDiscovery) ?? false).obs;

  bool _probing = false;

  @override
  void onInit() {
    super.onInit();
    probe();
  }

  /// Asks the server again; a failed request keeps the last known answer.
  Future<void> probe() async {
    if (_probing) return;
    _probing = true;
    try {
      final supported = await Get.find<OutpostRepository>().probeDiscovery();
      if (supported == null) return;
      discovery.value = supported;
      _storage.write(StorageKeys.serverHasDiscovery, supported);
    } finally {
      _probing = false;
    }
  }
}
