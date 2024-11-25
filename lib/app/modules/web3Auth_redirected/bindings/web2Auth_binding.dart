import 'package:get/get.dart';
import 'package:podium/app/modules/web3Auth_redirected/controllers/web3Auth_redirected_controller.dart';

class Web3AuthRedirectedBinding extends Binding {
  @override
  dependencies() => [
        Bind.put<Web3AuthRedirectedController>(
          Web3AuthRedirectedController(),
        ),
      ];
}
