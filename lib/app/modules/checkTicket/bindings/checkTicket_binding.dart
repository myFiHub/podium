import 'package:get/get.dart';
import 'package:podium/app/modules/checkTicket/controllers/checkTicket_controller.dart';

class CheckTicketBindings extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<CheckticketController>(
          () => CheckticketController(),
        )
      ];
}
