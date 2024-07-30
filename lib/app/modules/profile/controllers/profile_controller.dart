import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class ProfileController extends GetxController with BlockChainInteractions {
  final userInfo = Rxn<UserInfoModel>();
  final globalController = Get.find<GlobalController>();
  final connectedWallet = ''.obs;
  final isGettingTicketPrice = true.obs;
  final getPriceError = ''.obs;
  final ticketPriceFor1Share = 0.0.obs;

  @override
  void onInit() {
    userInfo.listen((user) {
      getBuyPriceForOneShare();
    });
    globalController.connectedWalletAddress.listen((a) {
      connectedWallet.value = a;
      getBuyPriceForOneShare();
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

  buyTicket() {
    log.f('implement buy ticket');
  }

  getBuyPriceForOneShare() async {
    try {
      getPriceError.value = '';
      isGettingTicketPrice.value = true;
      final user = userInfo.value;
      final connectedWalletAddress = globalController.connectedWalletAddress;
      if (user != null &&
          !user.localWalletAddress.isEmpty &&
          !(user.localWalletAddress == null) &&
          !connectedWalletAddress.isEmpty) {
        final price = await getBuyPrice(
          sharesSubject: user.localWalletAddress,
          shareAmount: 1,
        );
        isGettingTicketPrice.value = false;
        if (price != null) {
          // price is big int, in wei, convert to eth
          final BigInt priceInWei = price as BigInt;
          final BigInt weiToEthRatio = BigInt.from(10).pow(18);
          final double priceInEth =
              priceInWei.toDouble() / weiToEthRatio.toDouble();
          final String str = priceInEth.toString();
          ticketPriceFor1Share.value = double.parse(str.toString());
        }
      }
    } catch (e) {
      getPriceError.value = "error getting price, retry?";
    }
  }
}
