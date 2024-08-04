import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/mixins/particleAuth.dart';
import 'package:podium/app/modules/login/controllers/login_controller.dart';
import 'package:podium/constants/constantKeys.dart';
import 'package:podium/models/user_info_model.dart';
import 'package:podium/utils/logger.dart';

class SignUpController extends GetxController with ParticleAuthUtils {
  final globalController = Get.find<GlobalController>();
  final isSigningUp = false.obs;
  final fullName = ''.obs;
  final email = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final fileLocalAddress = ''.obs;
  final avatarSelectError = ''.obs;
  late File selectedFile;
  final ImagePicker _picker = ImagePicker();

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

  pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      selectedFile = File(pickedFile
          .path); // Use this to store the image in the database or cloud storage
      fileLocalAddress.value = pickedFile.path;
      avatarSelectError.value = '';
    } else {
      log.e('No image selected.');
      avatarSelectError.value = 'No image selected.';
    }
  }

  Future<String> uploadFile({required userId}) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('${FireBaseConstants.usersRef}$userId');

    // Upload the image to Firebase Storage
    final uploadTask = storageRef.putFile(selectedFile);

    // Wait for the upload to complete
    final snapshot = await uploadTask.whenComplete(() {});

    // Get the download URL of the uploaded image
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  signUp() async {
    isSigningUp.value = true;
    final enteredEmail = email.value;
    final enteredPassword = password.value;
    final enteredFullName = fullName.value;
    try {
      final particleUser = await particleLogin(email.value);
      if (particleUser != null) {
        globalController.particleAuthUserInfo.value = particleUser;
      } else {
        Get.snackbar('Error', 'Error Signing up');
        return;
      }
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: enteredEmail,
        password: enteredPassword,
      );
      final createdUserId = credential.user!.uid;

      final downloadUrl = await uploadFile(userId: credential.user!.uid);
      final usersDatabaseReference = FirebaseDatabase.instance
          .ref('${FireBaseConstants.usersRef}$createdUserId');

      final UserInfoModel userToCreate = UserInfoModel(
        id: createdUserId,
        fullName: enteredFullName,
        email: enteredEmail,
        avatar: downloadUrl,
        localWalletAddress: '',
        following: [],
        numberOfFollowers: 0,
        lowercasename: enteredFullName.toLowerCase(),
      );
      await usersDatabaseReference.set(userToCreate.toJson());
      final LoginController loginController = Get.put(LoginController());
      loginController.login(
          manualEmail: enteredEmail,
          manualPassword: enteredPassword,
          fromSignUp: true);
    } on FirebaseAuthException catch (e) {
      log.e('firebase auth error :' + e.toString());
      if (e.code == 'email-already-in-use') {
        Get.snackbar('Error', 'this email is already in use');
      } else {
        Get.snackbar('Error', 'Something went wrong');
      }
    } on FirebaseException catch (e) {
      log.e('firebase error :' + e.toString());
    } catch (e) {
      log.e('error :' + e.toString());
    } finally {
      isSigningUp.value = false;
    }
  }
}
