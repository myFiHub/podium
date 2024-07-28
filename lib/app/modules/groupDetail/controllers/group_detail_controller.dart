import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/groups_controller.dart';
import 'package:podium/app/modules/global/mixins/firebase.dart';
import 'package:podium/models/firebase_group_model.dart';
import 'package:podium/models/user_info_model.dart';

class GroupDetailController extends GetxController with FireBaseUtils {
  final groupsController = Get.find<GroupsController>();
  final isGettingMembers = false.obs;
  final group = Rxn<FirebaseGroup>();
  final membersList = Rx<List<UserInfoModel>>([]);
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

  getMembers(FirebaseGroup group) async {
    final memberIds = group.members;
    isGettingMembers.value = true;
    final list = await getUsersByIds(memberIds);
    membersList.value = list;
    isGettingMembers.value = false;
  }
}
