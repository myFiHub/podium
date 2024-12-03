import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/env.dart';
import 'package:podium/models/referral/referral.dart';
import 'package:podium/services/toast/toast.dart';

class ReferalController extends GetxController {
  final GlobalController globalController = Get.find<GlobalController>();
  final myReferals = Rx<Map<String, Referral>>({});
  StreamSubscription<DatabaseEvent>? myReferalsStream = null;

  @override
  void onInit() {
    globalController.loggedIn.listen((loggedIn) async {
      if (loggedIn) {
        myReferalsStream = startListeningToMyReferals((referals) {
          myReferals.value = referals;
        });
      } else {
        myReferals.value = {};
        myReferalsStream?.cancel();
      }
    });
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    myReferalsStream?.cancel();
  }

  Future<Map<String, Referral>> getAllTheReferals(
      {required String userId}) async {
    final referals = await getAllTheUserReferals(userId: userId);
    return referals;
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
