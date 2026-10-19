// Define the dialog opening function
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/app/modules/global/widgets/Img.dart';
import 'package:podium/app/services/image_service.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/utils/constants.dart';
import 'package:podium/widgets/ui/app_ui.dart';

void openOutpostImageDialog({
  required OutpostModel outpost,
  Future<void> Function(String downloadUrl)? onComplete,
}) {
  Get.dialog(
    Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: _OpenImageDialogContent(
        outpost: outpost,
        onComplete: onComplete,
      ),
    ),
  );
}

class _OpenImageDialogContent extends StatelessWidget {
  final OutpostModel outpost;
  final Future<void> Function(String downloadUrl)? onComplete;

  const _OpenImageDialogContent({
    required this.outpost,
    this.onComplete,
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
  final Future<void> Function(String downloadUrl)? onUploadComplete;

  const ImageDialogStack({
    super.key,
    required this.imageUrl,
    required this.imageAlt,
    required this.iAmOwner,
    required this.outpostId,
    this.onUploadComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    imageAlt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Close',
                size: 36,
                onTap: () => Get.close(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          EditableImage(
            imageSrc: imageUrl,
            imageAlt: imageAlt,
            iAmOwner: iAmOwner,
            outpostId: outpostId,
            onUploadComplete: onUploadComplete,
          ),
        ],
      ),
    );
  }
}

// Convert to StatefulWidget
class EditableImage extends StatefulWidget {
  final String imageSrc;
  final String imageAlt;
  final bool iAmOwner;
  final String outpostId;
  final Future<void> Function(String downloadUrl)? onUploadComplete;

  EditableImage({
    super.key,
    required this.imageSrc,
    required this.imageAlt,
    required this.iAmOwner,
    required this.outpostId,
    this.onUploadComplete,
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
    if (widget.imageSrc != oldWidget.imageSrc && mounted) {
      setState(() {
        _currentImageSrc = widget.imageSrc;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Img(
              // Use state variable for image source
              src: _currentImageSrc,
              size: constraints.maxWidth,
              alt: widget.imageAlt,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            );
          },
        ),
        if (widget.iAmOwner) ...[
          const SizedBox(height: 16),
          Obx(
            () => AppPrimaryButton(
              label: 'Change Image',
              icon: Icons.image_outlined,
              loading: imageService.isUploadingImage.value,
              onPressed: () async {
                final downloadUrl = await imageService.pickAndUploadImage(
                  outpostId: widget.outpostId,
                );
                if (downloadUrl != null && mounted) {
                  // Update local state first
                  setState(() {
                    _currentImageSrc = downloadUrl;
                  });
                  // Then call the provided callback if it exists
                  if (widget.onUploadComplete != null) {
                    await widget.onUploadComplete!(downloadUrl);
                  }
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
