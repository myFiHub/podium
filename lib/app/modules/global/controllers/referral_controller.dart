import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/env.dart';
import 'package:podium/models/referral/referral.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/auth/additionalDataForLogin.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';

class ReferalController extends GetxController {
  final GlobalController globalController = Get.find<GlobalController>();
  final myProfile = Rxn<UserModel>();
  StreamSubscription<bool>? loggedInListener;
  @override
  void onInit() {
    super.onInit();
    loggedInListener = globalController.loggedIn.listen((loggedIn) async {
      if (loggedIn) {
        final profile = await HttpApis.podium
            .getMyUserData(additionalData: AdditionalDataForLogin());

        myProfile.value = profile;
      } else {}
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    loggedInListener?.cancel();
  }

  referButtonClicked() async {
    Clipboard.setData(ClipboardData(text: '${generateReferralLink()}'));
    Toast.success(
      title: 'Copied!',
      message: 'Referral link copied to clipboard',
    );
  }
}

generateReferralLink() {
  return "${Env.baseDeepLinkUrl}/?link=${Env.baseDeepLinkUrl}/referral?referrerId=${myId}&apn=com.web3podium";
}
