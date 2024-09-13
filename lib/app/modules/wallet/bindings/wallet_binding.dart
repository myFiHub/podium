import 'package:get/get.dart';

import '../controllers/wallet_controller.dart';

class WalletBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<WalletController>(
          () => WalletController(),
        )
      ];
}
