import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/utils/navigation/navigation.dart';

import 'package:podium/utils/storage.dart';

class LoginController extends GetxController {
  final globalController = Get.find<GlobalController>();
  final isLoggingIn = false.obs;
  final email = ''.obs;
  final password = ''.obs;

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

  login({String? manualEmail, String? manualPassword}) async {
    isLoggingIn.value = true;
    final enteredEmail = manualEmail == null ? email.value : manualEmail;
    final enteredPassword =
        manualPassword == null ? password.value : manualPassword;
    try {
      UserCredential firebaseUserCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: enteredEmail.trim(),
        password: enteredPassword.trim(),
      );
      final user = FirebaseAuth.instance.currentUser;
      globalController.firebaseUser.value = user;
      try {
        final currentUserInfo =
            await globalController.getUserInfoById(user!.uid);
        globalController.currentUserInfo.value = currentUserInfo;
        final storage = GetStorage();
        storage.write(StorageKeys.userEmail, enteredEmail);
        globalController.firebaseUserCredential.value = firebaseUserCredential;
        globalController.setLoggedIn(true);
        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: Routes.HOME,
        );
      } catch (e) {
        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: Routes.LOGIN,
        );
        return;
      }
    } on FirebaseAuthException catch (e) {
      // Handle errors, such as invalid email or password
      log.e('Error signing in: ${e.code}');
      final errorMessage = e.message == 'invalid-credential'
          ? 'Invalid email or password'
          : e.message;
      Get.snackbar('Error', errorMessage ?? 'Error logging in');
    } catch (e) {
      log.e('Error signing in: $e');
    } finally {
      isLoggingIn.value = false;
    }
  }
}
