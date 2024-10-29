import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> getPermission(Permission featureToRequest) async {
  final status = await featureToRequest.status;
  if (status.isGranted) {
    return true;
  } else if (status.isPermanentlyDenied) {
    AppSettings.openAppSettings(type: AppSettingsType.settings);
    return false;
  } else if (status.isDenied) {
    await featureToRequest.request();
    return await getPermission(featureToRequest);
  } else {
    return false;
  }
}
