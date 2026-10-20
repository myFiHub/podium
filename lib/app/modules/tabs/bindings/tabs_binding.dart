import 'package:get/get.dart';
import 'package:podium/app/modules/allOutposts/bindings/all_groups_binding.dart';
import 'package:podium/app/modules/home/bindings/home_binding.dart';
import 'package:podium/app/modules/myProfile/bindings/my_profile_binding.dart';
import 'package:podium/app/modules/search/bindings/search_binding.dart';

/// Controllers for every navbar tab. They live as long as the tabs page, so
/// switching tabs keeps their state. NotificationsController is global.
class TabsBinding extends Binding {
  @override
  List<Bind> dependencies() => [
        ...HomeBinding().dependencies(),
        ...AllGroupsBinding().dependencies(),
        ...SearchBinding().dependencies(),
        ...MyProfileBinding().dependencies(),
      ];
}
