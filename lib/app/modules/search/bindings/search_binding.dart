import 'package:get/get.dart';

import '../controllers/search_controller.dart';

class SearchBinding extends Binding {
  @override
  dependencies() => [
        Bind.lazyPut<SearchController>(
          () => SearchController(),
        )
      ];
}
