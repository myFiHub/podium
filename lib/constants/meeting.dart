import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/env.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/constants.dart';

class MeetingConstants {
  static Map<String, Object?> featureFlags(
      {required bool allowedToSpeak, required FirebaseGroup group}) {
    final globalController = Get.find<GlobalController>();
    final creatorId = group.creator.id;
    final myId = globalController.currentUserInfo.value!.id;
    final iAmCreator = creatorId == myId;
    return {
      FeatureFlags.unsafeRoomWarningEnabled: false,
      FeatureFlags.securityOptionEnabled: false,
      FeatureFlags.iosScreenSharingEnabled: true,
      FeatureFlags.toolboxAlwaysVisible: true,
      FeatureFlags.inviteEnabled: false,
      FeatureFlags.raiseHandEnabled: allowedToSpeak,
      FeatureFlags.videoShareEnabled: false,
      FeatureFlags.recordingEnabled: false,
      FeatureFlags.welcomePageEnabled: false,
      FeatureFlags.preJoinPageEnabled: false,
      FeatureFlags.pipEnabled: true,
      FeatureFlags.kickOutEnabled: iAmCreator,
      FeatureFlags.fullScreenEnabled: true,
      FeatureFlags.reactionsEnabled: true,
      FeatureFlags.videoMuteEnabled: false,
      FeatureFlags.audioMuteButtonEnabled: allowedToSpeak,
    };
  }

  static Map<String, Object?> configOverrides(FirebaseGroup g) {
    return {
      "startWithAudioMuted": true,
      "startWithVideoMuted": true,
      "subject": g.name,
      "localSubject": g.name,
    };
  }

  static JitsiMeetConferenceOptions buildMeetOptions({
    required FirebaseGroup group,
    required UserInfoModel myUser,
    required bool allowedToSpeak,
  }) {
    final globalController = Get.find<GlobalController>();
    final sa = globalController.jitsiServerAddress;
    String avatar = myUser.avatar;
    // ignore: unnecessary_null_comparison
    if (avatar == null || avatar.isEmpty) {
      avatar = avatarPlaceHolder(myUser.fullName);
    }
    return JitsiMeetConferenceOptions(
      serverURL: sa != '' ? sa : Env.jitsiServerUrl,
      room: group.id,
      configOverrides: configOverrides(group),
      featureFlags: featureFlags(
        group: group,
        allowedToSpeak: allowedToSpeak,
      ),
      userInfo: JitsiMeetUserInfo(
        displayName: myUser.fullName,
        email: myUser.email,
        avatar: avatar,
        id: myUser.id,
      ),
    );
  }
}
