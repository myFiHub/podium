import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/controllers/group_call_controller.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';

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
    final globalController = Get.find<GlobalController>();
    final groupsController = Get.find<GroupsController>();
    if (globalController.loggedIn.value) {
      groupsController.joinGroupAndOpenGroupDetailPage(
        groupId: id,
      );
    } else {
      Get.offAllNamed(Routes.LOGIN);
      final loginController = Get.put(LoginController());
      loginController.afterLogin = () {
        groupsController.joinGroupAndOpenGroupDetailPage(
          groupId: id,
        );
      };
    }
    isGettingGroupInfo.value = false;
  }

  getMembers(FirebaseGroup group) async {
    final memberIds = group.members;
    isGettingMembers.value = true;
    final list = await getUsersByIds(memberIds);
    membersList.value = list;
    isGettingMembers.value = false;
  }

  startTheCall() {
    final groupCallController = Get.find<GroupCallController>();
    groupCallController.startCall(
      groupToJoin: group.value!,
    );
  }
}
