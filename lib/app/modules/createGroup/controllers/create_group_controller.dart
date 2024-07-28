import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/navigation/navigation.dart';

class CreateGroupController extends GetxController {
  final groupsController = Get.find<GroupsController>();
  final isCreatingNewGroup = false.obs;
  final groupName = "".obs;
  @override
  void onInit() {
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

  create() async {
    isCreatingNewGroup.value = true;
    await groupsController.createGroup(groupName.value);
    isCreatingNewGroup.value = false;
    Navigate.to(
      type: NavigationTypes.offAllAndToNamed,
      route: Routes.HOME,
    );
  }
}
