import 'package:get/get.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/env.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/constants.dart';

class MeetingConstants {
  static Map<String, Object?> featureFlags(
      {required bool allowedToSpeak, required FirebaseGroup group}) {
    final creatorId = group.creator.id;
    final iAmCreator = creatorId == myId;
    return {
      FeatureFlags.unsafeRoomWarningEnabled: false,
      FeatureFlags.securityOptionEnabled: false,
      FeatureFlags.iosScreenSharingEnabled: true,
      FeatureFlags.androidScreenSharingEnabled: true,
      FeatureFlags.toolboxAlwaysVisible: true,
      FeatureFlags.inviteEnabled: false,
      FeatureFlags.raiseHandEnabled: allowedToSpeak,
      FeatureFlags.videoShareEnabled: false,
      FeatureFlags.recordingEnabled: iAmCreator,
      FeatureFlags.iosRecordingEnabled: iAmCreator,
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
    if (avatar == null || avatar.isEmpty || avatar == defaultAvatar) {
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
        // this is crucial for us to pass the email like this,
        // since cheering and booing listeners return email,
        // we use that email to determine who is being cheered/booed
        email: transformIdToEmailLike(myUser.id),
        avatar: avatar,
      ),
    );
  }
}

// transform 054dfc78-c174-49dc-a620-0f0da86d0400 to 054dfc78c17449dca6200f0da86d0400@gmail.com
transformIdToEmailLike(String id) {
  final rawId = id.replaceAll('-', '');
  return '$rawId@gmail.com';
}

// transform 054dfc78c17449dca6200f0da86d0400@gmail.com to 054dfc78-c174-49dc-a620-0f0da86d0400
transformEmailLikeToId(String email) {
  final parts = email.split('@');
  final id = parts[0];
  final idParts = id.split('');
  final idLength = idParts.length;
  final firstPart = idParts.sublist(0, 8).join();
  final secondPart = idParts.sublist(8, 12).join();
  final thirdPart = idParts.sublist(12, 16).join();
  final fourthPart = idParts.sublist(16, 20).join();
  final fifthPart = idParts.sublist(20, idLength).join();
  return '$firstPart-$secondPart-$thirdPart-$fourthPart-$fifthPart';
}
