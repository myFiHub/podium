import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/blockChainInteraction.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

class ProfileController extends GetxController with BlockChainInteractions {
  final userInfo = Rxn<UserInfoModel>();
  final globalController = Get.find<GlobalController>();
  final connectedWallet = ''.obs;
  final isGettingTicketPrice = true.obs;
  final getPriceError = ''.obs;
  final ticketPriceFor1Share = 0.0.obs;
  final isBuyingTicket = false.obs;

  @override
  void onInit() {
    connectedWallet.value = globalController.connectedWalletAddress.value;
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

  buyTicket() async {
    try {
      isBuyingTicket.value = true;
      final String? result = await buySharesWithReferrer(
        sharesSubject: userInfo.value!.localWalletAddress,
        shareAmount: 1,
        value: ticketPriceFor1Share.value,
      );
      log.d(result);
      if (result != null) {
        if (result.startsWith("0x")) {
          Get.snackbar(
            'Success',
            "ticket bought",
            colorText: ColorName.white,
          );
        } else {
          Get.snackbar(
            'Error',
            "Error buying ticket",
            colorText: ColorName.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          "Error buying ticket",
          colorText: ColorName.white,
        );
      }
    } catch (e) {
      log.e("error buying ticket ${e.toString()}");
    } finally {
      isBuyingTicket.value = false;
    }
  }

  getBuyPriceForOneShare() async {
    try {
      getPriceError.value = '';
      isGettingTicketPrice.value = true;
      final user = userInfo.value;
      final connectedWalletAddress = globalController.connectedWalletAddress;
      if (user != null &&
          !user.localWalletAddress.isEmpty &&
          // ignore: unnecessary_null_comparison
          user.localWalletAddress != null &&
          !connectedWalletAddress.isEmpty) {
        final price = await getBuyPrice(
          sharesSubject: user.localWalletAddress,
          shareAmount: 1,
        );
        isGettingTicketPrice.value = false;
        if (price != null) {
          final double priceInEth = bigIntWeiToDouble(price);
          final String str = priceInEth.toString();
          ticketPriceFor1Share.value = double.parse(str.toString());
          isGettingTicketPrice.value = false;
        }
      }
    } catch (e) {
      getPriceError.value = "error getting price, retry?";
      isGettingTicketPrice.value = false;
    }
  }
}
