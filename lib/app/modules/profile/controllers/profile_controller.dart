import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';

import 'package:podium/models/user_info_model.dart';

class ProfileController extends GetxController with BlockChainInteractions {
  final userInfo = Rxn<UserInfoModel>();
  final globalController = Get.find<GlobalController>();
  final connectedWallet = ''.obs;
  final isGettingTicketPrice = false.obs;
  final getPriceError = ''.obs;
  final ticketPriceFor1Share = 0.0.obs;
  final isBuyingTicket = false.obs;

  @override
  void onInit() {
    connectedWallet.value = globalController.connectedWalletAddress.value;

    globalController.connectedWalletAddress.listen((a) {
      connectedWallet.value = a;
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
  }
}
