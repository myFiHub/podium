import '../controllers/create_outpost_controller.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/widgets/tags_input.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class SelectPicture extends GetWidget<CreateOutpostController> {
  const SelectPicture({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedFile = controller.fileLocalAddress.value;
      final hasImage = selectedFile != '';
      return SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: ColorName.white.withAlpha(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: hasImage
                        ? Colors.transparent
                        : AppColors.primary.withAlpha(90),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    controller.pickImage();
                  },
                  child: hasImage
                      ? Image.file(
                          File(selectedFile),
                          fit: BoxFit.cover,
                          cacheWidth: 320,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 28,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cover',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'max 2MB',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            if (hasImage)
              Positioned(
                right: -4,
                bottom: -4,
                child: IgnorePointer(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorName.cardBackground,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: ColorName.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class TagsInput extends GetWidget<CreateOutpostController> {
  const TagsInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicTags(
      onTagsChanged: (values) {
        controller.setTags(values);
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  final String hintText;
  final String initialValue;
  final ValueChanged<String> onChanged;
  const _TextInput({
    required this.hintText,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardAppearance: Brightness.dark,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ColorName.white,
      ),
      decoration: InputDecoration(hintText: hintText),
    );
  }
}

class SubjectInput extends GetWidget<CreateOutpostController> {
  const SubjectInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _TextInput(
      initialValue: controller.outpostSubject.value,
      hintText: 'Main subject (optional)',
      onChanged: (value) => controller.outpostSubject.value = value,
    );
  }
}

class OutpostNameInput extends GetWidget<CreateOutpostController> {
  const OutpostNameInput({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _TextInput(
      hintText: 'Outpost name',
      initialValue: controller.outpostName.value,
      onChanged: (value) => controller.outpostName.value = value,
    );
  }
}
