import 'package:get/get.dart';

import '../controllers/chat_controller.dart';

class ChatBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<ChatController>(
          () => ChatController(),
        )
      ];
}
