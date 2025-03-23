import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/env.dart';
import 'package:podium/models/referral/referral.dart';
import 'package:podium/services/toast/toast.dart';

class ReferalController extends GetxController {
  final GlobalController globalController = Get.find<GlobalController>();
  final myReferals = Rx<Map<String, Referral>>({});
  StreamSubscription<DatabaseEvent>? myReferalsStream = null;
  StreamSubscription<bool>? loggedInListener;
  @override
  void onInit() {
    super.onInit();
    loggedInListener = globalController.loggedIn.listen((loggedIn) async {
      if (loggedIn) {
        // TODO: listen to referrals used
      } else {
        myReferals.value = {};
        myReferalsStream?.cancel();
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    myReferalsStream?.cancel();
    loggedInListener?.cancel();
  }

  Future<Map<String, Referral>> getAllTheReferals(
      {required String userId}) async {
    // final referals = await getAllTheUserReferals(userId: userId);
    // TODO: get all referrals
    return {};
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
