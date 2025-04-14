// Define the dialog opening function
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/services/image_service.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';

void openOutpostImageDialog({
  required OutpostModel outpost,
  required Future<void> Function(String downloadUrl) onComplete,
}) {
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: _OpenImageDialogContent(
        outpost: outpost,
        onComplete: onComplete,
      ),
    ),
  );
}

class _OpenImageDialogContent extends StatelessWidget {
  final OutpostModel outpost;
  final Future<void> Function(String downloadUrl) onComplete;

  const _OpenImageDialogContent({
    super.key,
    required this.outpost,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = outpost.image.isEmpty ? Constants.logoUrl : outpost.image;
    final iAmOwner = outpost.creator_user_uuid == myId;

    return ImageDialogStack(
      imageUrl: imageUrl,
      imageAlt: outpost.name,
      iAmOwner: iAmOwner,
      outpostId: outpost.uuid,
      onUploadComplete: onComplete,
    );
  }
}

class ImageDialogStack extends StatelessWidget {
  final String imageUrl;
  final String imageAlt;
  final bool iAmOwner;
  final String outpostId;
  final Future<void> Function(String downloadUrl) onUploadComplete;

  const ImageDialogStack({
    super.key,
    required this.imageUrl,
    required this.imageAlt,
    required this.iAmOwner,
    required this.outpostId,
    required this.onUploadComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: ColorName.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          padding:
              const EdgeInsets.only(top: 65, left: 24, right: 24, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EditableImage(
                imageSrc: imageUrl,
                imageAlt: imageAlt,
                iAmOwner: iAmOwner,
                outpostId: outpostId,
                onUploadComplete: onUploadComplete,
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.close(),
          ),
        ),
      ],
    );
  }
}

// Convert to StatefulWidget
class EditableImage extends StatefulWidget {
  final String imageSrc;
  final String imageAlt;
  final bool iAmOwner;
  final String outpostId;
  final Future<void> Function(String downloadUrl) onUploadComplete;

  EditableImage({
    super.key,
    required this.imageSrc,
    required this.imageAlt,
    required this.iAmOwner,
    required this.outpostId,
    required this.onUploadComplete,
  });

  @override
  State<EditableImage> createState() => _EditableImageState();
}

class _EditableImageState extends State<EditableImage> {
  // Inject ImageService
  final OutpostImageService imageService = Get.find();
  late String _currentImageSrc;

  @override
  void initState() {
    super.initState();
    _currentImageSrc = widget.imageSrc;
  }

  // Update state if the initial prop changes
  @override
  void didUpdateWidget(covariant EditableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageSrc != oldWidget.imageSrc) {
      setState(() {
        _currentImageSrc = widget.imageSrc;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Img(
          // Use state variable for image source
          src: _currentImageSrc,
          size: 300,
          alt: widget.imageAlt,
        ),
        if (widget.iAmOwner) ...[
          space16,
          Obx(
            () => SizedBox(
              width: 140,
              child: Button(
                blockButton: true,
                loading: imageService.isUploadingImage.value,
                type: ButtonType.outline,
                size: ButtonSize.MEDIUM,
                onPressed: () async {
                  final downloadUrl = await imageService.pickAndUploadImage(
                    outpostId: widget.outpostId,
                  );
                  if (downloadUrl != null) {
                    // Update local state first
                    setState(() {
                      _currentImageSrc = downloadUrl;
                    });
                    // Then call the provided callback
                    await widget.onUploadComplete(downloadUrl);
                  }
                },
                child: const Text('Change Image'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
