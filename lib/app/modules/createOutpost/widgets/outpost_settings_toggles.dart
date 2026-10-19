import '../controllers/create_outpost_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/widgets/cohosts_widget.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class AdultsCheckbox extends GetView<CreateOutpostController> {
  const AdultsCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isChecked = controller.newOutpostHasAdultContent.value;
        return AppSettingsRow(
          dense: true,
          icon: Icons.eighteen_up_rating_outlined,
          iconColor: AppColors.danger,
          title: 'Adults speaking',
          subtitle: 'Room content for 18+',
          onTap: () {
            controller.newOutpostHasAdultContent.value = !isChecked;
          },
          trailing: Switch(
            value: isChecked,
            activeTrackColor: AppColors.danger,
            onChanged: (value) {
              controller.newOutpostHasAdultContent.value = value;
            },
          ),
        );
      },
    );
  }
}

class RecordableCheckbox extends GetView<CreateOutpostController> {
  const RecordableCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final isChecked = controller.newOutpostIsRecorable.value;
        return AppSettingsRow(
          dense: true,
          icon: Icons.radio_button_checked_rounded,
          iconColor: AppColors.danger,
          title: 'Recordable',
          subtitle: 'Outpost sessions can be recorded by you',
          onTap: () {
            controller.newOutpostIsRecorable.value = !isChecked;
          },
          trailing: Switch(
            value: isChecked,
            onChanged: (value) {
              controller.newOutpostIsRecorable.value = value;
            },
          ),
        );
      },
    );
  }
}

class SelectCohosts extends GetView<CreateOutpostController> {
  const SelectCohosts({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cohosts = controller.cohosts.value;
      final count = cohosts.length;
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AppSettingsRow(
          dense: true,
          icon: Icons.group_add_rounded,
          title: 'Cohosts',
          subtitle: count == 0
              ? 'Add cohosts to help manage the outpost'
              : '$count cohost${count > 1 ? 's' : ''} selected · tap to review',
          onTap: count == 0
              ? () => _showAddCohostsBottomSheet()
              : () => _showCohostsDialog(),
          trailing: AppIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Add cohosts',
            size: 36,
            color: AppColors.primary,
            background: AppColors.primary.withAlpha(24),
            onTap: () => _showAddCohostsBottomSheet(),
          ),
        ),
      );
    });
  }

  void _showCohostsDialog() {
    Get.dialog(
      AppDialogMotion(
        child: AlertDialog(
          title: const Text('Selected Cohosts'),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          content: Obx(() {
            final cohosts = controller.cohosts.value;
            if (cohosts.isEmpty) {
              return const AppEmptyState(
                icon: Icons.group_outlined,
                title: 'No cohosts selected',
                compact: true,
              );
            }
            return SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cohosts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cohost = cohosts[index];
                  final hasImage =
                      cohost.image != null && cohost.image!.isNotEmpty;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withAlpha(40),
                          backgroundImage: hasImage
                              ? CachedNetworkImageProvider(
                                  cohost.image!,
                                  maxWidth: 160,
                                )
                              : null,
                          child: hasImage
                              ? null
                              : Icon(
                                  Icons.person_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cohost.name ?? 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: AppColors.danger,
                          ),
                          onPressed: () {
                            controller.cohosts.removeAt(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
          actions: [
            TextButton(
              onPressed: () => Get.closeOverlay(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCohostsBottomSheet() {
    Get.bottomSheet(
      CohostsSearchBottomSheet(
        initialCohostUuids:
            controller.cohosts.value.map((u) => u.uuid).toList(),
        isCreator: true, // Always true for create outpost
        onConfirm: (cohostUuids) {
          // Convert UUIDs back to UserModel objects
          final currentCohosts = controller.cohosts.value;
          final newCohosts = cohostUuids.map((uuid) {
            return currentCohosts.firstWhere(
              (user) => user.uuid == uuid,
              orElse: () => UserModel(
                uuid: uuid,
                address: '',
                name: 'Unknown User',
              ),
            );
          }).toList();
          controller.cohosts.value = newCohosts;
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
