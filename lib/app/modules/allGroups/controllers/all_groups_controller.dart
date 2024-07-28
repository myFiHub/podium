import 'package:get/get.dart';
import 'package:podium/app/modules/allGroups/mixins/allGroupsFirebaseUtils.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/utils/throttleAndDebounce/debounce.dart';

final deb = Debouncing(duration: const Duration(seconds: 1));

class AllGroupsController extends GetxController with AllGroupsFirebaseUtils {
  final groupsController = Get.find<GroupsController>();
  final searchValue = ''.obs;
  final searchedGroups = Rxn<Map<String, FirebaseGroup>>({});

  @override
  void onInit() {
    super.onInit();
    searchValue.listen((value) async {
      deb.debounce(() async {
        final groups = await searchForGroupByName(value);
        if (value.isEmpty) {
          searchedGroups.value = groupsController.groups.value;
        } else {
          searchedGroups.value = groups;
        }
      });
    });
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
