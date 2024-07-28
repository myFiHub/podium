import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/env.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';

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
  };
  static Map<String, Object?> configOverrides(FirebaseGroup g) {
    return {
      "startWithAudioMuted": true,
      "startWithVideoMuted": true,
      "subject": g.name,
      "localSubject": g.name,
    };
  }

  static buildMeetOptions(
      {required FirebaseGroup group, required UserInfoModel myUser}) {
    return JitsiMeetConferenceOptions(
      serverURL: Env.jitsiServerUrl,
      room: group.id,
      configOverrides: configOverrides(group),
      featureFlags: featureFlags,
      userInfo: JitsiMeetUserInfo(
        displayName: myUser.fullName,
        email: myUser.email,
        avatar: myUser.avatar,
      ),
    );
  }
}
