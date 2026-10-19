import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/createOutpost/widgets/luma_people_dialog.dart';

class AddHostsPopup extends GetView<CreateOutpostController> {
  const AddHostsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return LumaPeopleDialog(
      title: 'Add Hosts',
      subtitle: 'They can manage the Luma event with you',
      listLabel: 'Hosts',
      addLabel: 'Add Host',
      emptyIcon: Icons.mic_external_on_rounded,
      emptyTitle: 'No hosts added yet',
      people: () => controller.lumaHosts.value
          .map((h) => LumaPerson(email: h.email, name: h.name))
          .toList(),
      onAdd: (email, name) => controller.addHost(email, name),
      onRemove: (email) => controller.removeHost(email),
    );
  }
}

openAddHostsDialog() {
  Get.dialog(
    const AddHostsPopup(),
  );
}
