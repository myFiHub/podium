import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/env.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/constants.dart';

class MeetingConstants {
  static Map<String, Object?> featureFlags = {
    FeatureFlags.unsafeRoomWarningEnabled: false,
    FeatureFlags.securityOptionEnabled: false,
    FeatureFlags.iosScreenSharingEnabled: true,
    FeatureFlags.toolboxAlwaysVisible: true,
    FeatureFlags.inviteEnabled: false,
    FeatureFlags.raiseHandEnabled: true,
    FeatureFlags.videoShareEnabled: false,
    FeatureFlags.recordingEnabled: false,
    FeatureFlags.welcomePageEnabled: false,
    FeatureFlags.preJoinPageEnabled: false,
    FeatureFlags.pipEnabled: true,
    FeatureFlags.kickOutEnabled: false,
    FeatureFlags.fullScreenEnabled: true,
    FeatureFlags.reactionsEnabled: false,
    FeatureFlags.videoMuteEnabled: false,
    FeatureFlags.audioMuteButtonEnabled: false,
  };
  static Map<String, Object?> configOverrides(FirebaseGroup g) {
    return {
      "startWithAudioMuted": true,
      "startWithVideoMuted": true,
      "subject": g.name,
      "localSubject": g.name,
    };
  }

  static JitsiMeetConferenceOptions buildMeetOptions(
      {required FirebaseGroup group, required UserInfoModel myUser}) {
    final globalController = Get.find<GlobalController>();
    final sa = globalController.jitsiServerAddress;
    String avatar = myUser.avatar;
    // ignore: unnecessary_null_comparison
    if (avatar == null || avatar.isEmpty) {
      avatar = Constants.defaultProfilePic;
    }
    return JitsiMeetConferenceOptions(
      serverURL: sa != '' ? sa : Env.jitsiServerUrl,
      room: group.id,
      configOverrides: configOverrides(group),
      featureFlags: featureFlags,
      userInfo: JitsiMeetUserInfo(
        displayName: myUser.fullName,
        email: myUser.email,
        avatar: avatar,
        id: myUser.id,
      ),
    );
  }
}
