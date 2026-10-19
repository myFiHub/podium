import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/createOutpost/controllers/create_outpost_controller.dart';
import 'package:podium/app/modules/createOutpost/widgets/luma_people_dialog.dart';

class AddGuestsPopup extends GetView<CreateOutpostController> {
  const AddGuestsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return LumaPeopleDialog(
      title: 'Add Guests',
      subtitle: 'They will be invited to the Luma event',
      listLabel: 'Guests',
      addLabel: 'Add Guest',
      emptyIcon: Icons.people_alt_rounded,
      emptyTitle: 'No guests added yet',
      people: () => controller.lumaGuests.value
          .map((g) => LumaPerson(email: g.email, name: g.name))
          .toList(),
      onAdd: (email, name) => controller.addGuest(email, name),
      onRemove: (email) => controller.removeGuest(email),
    );
  }
}

openAddGuestsDialog() {
  Get.dialog(
    const AddGuestsPopup(),
  );
}
