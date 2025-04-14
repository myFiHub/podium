import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podium/app/modules/global/controllers/outposts_controller.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';

class OutpostImageService extends GetxService {
  final ImagePicker _picker = ImagePicker();
  final RxBool isUploadingImage = false.obs;

  Future<String?> pickAndUploadImage({required String outpostId}) async {
    isUploadingImage.value = true;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = file.lengthSync();

        // Check if file is less than 2MB
        if (fileSize > 2 * 1024 * 1024) {
          Toast.error(message: 'Image size must be less than 2MB');
          return null;
        }

        // Upload to Firebase Storage
        final storageRef =
            FirebaseStorage.instance.ref().child('outposts/$outpostId');
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        final outpostsController = Get.find<OutpostsController>();
        final outpost = await HttpApis.podium.getOutpost(outpostId);
        if (outpost != null) {
          final url =
              await outpostsController.uploadOutpostImage(outpost, downloadUrl);
          return url;
        }
        return null;
      } else {
        l.w('No image selected.');
        return null;
      }
    } catch (e) {
      l.e('Error picking or uploading image: $e');
      Toast.error(message: 'Failed to process image.');
      return null;
    } finally {
      isUploadingImage.value = false;
    }
  }
}
