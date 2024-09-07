import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

class GroupDetailController extends GetxController with FireBaseUtils {
  final groupsController = Get.find<GroupsController>();
  final isGettingMembers = false.obs;
  final group = Rxn<FirebaseGroup>();
  final membersList = Rx<List<UserInfoModel>>([]);
  final isGettingGroupInfo = false.obs;

  @override
  void onInit() {
    super.onInit();
    group.listen((group) {
      if (group != null) {
        getMembers(group);
      }
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

  getGroupInfo({required String id}) async {
    if (isGettingGroupInfo.value) return;
    isGettingGroupInfo.value = true;
    final remoteGroup = await getGroupInfoById(id);
    group.value = remoteGroup;
    if (remoteGroup == null) {
      Get.snackbar('Error', 'Group not found');
    }
    final globalController = Get.find<GlobalController>();
    final groupsController = Get.find<GroupsController>();
    if (globalController.loggedIn.value) {
      groupsController.joinGroup(id);
    } else {
      Get.offAllNamed(Routes.LOGIN);
      final loginController = Get.put(LoginController());
      log.d('Setting after login');
      loginController.afterLogin = () {
        Get.offAllNamed(
          '${Routes.GROUP_DETAIL}/$id',
        );
      };
    }
    isGettingGroupInfo.value = false;

    // groupsController.joinGroup(id);
    // Get.toNamed(Routes.GROUP_DETAIL);
  }

  getMembers(FirebaseGroup group) async {
    final memberIds = group.members;
    isGettingMembers.value = true;
    final list = await getUsersByIds(memberIds);
    membersList.value = list;
    isGettingMembers.value = false;
  }
}
