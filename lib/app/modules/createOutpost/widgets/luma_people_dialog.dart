import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/widgets/ui/app_ui.dart';

class LumaPerson {
  final String email;
  final String? name;
  const LumaPerson({required this.email, this.name});
}

class LumaPeopleDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String listLabel;
  final String addLabel;
  final IconData emptyIcon;
  final String emptyTitle;
  final List<LumaPerson> Function() people;
  final void Function(String email, String name) onAdd;
  final void Function(String email) onRemove;
  const LumaPeopleDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.listLabel,
    required this.addLabel,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.people,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.title),
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppText.caption),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    size: 36,
                    onTap: () => Get.closeOverlay(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PersonForm(addLabel: addLabel, onAdd: onAdd),
                    Obx(() {
                      final list = people();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSectionHeader(
                            title: listLabel,
                            count: list.length,
                            padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
                          ),
                          if (list.isEmpty)
                            AppEmptyState(
                              icon: emptyIcon,
                              title: emptyTitle,
                              compact: true,
                            )
                          else
                            for (final person in list)
                              _PersonTile(
                                person: person,
                                onRemove: () => onRemove(person.email),
                              ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: AppSecondaryButton(
                label: 'Done',
                onPressed: () => Get.closeOverlay(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonForm extends StatefulWidget {
  final String addLabel;
  final void Function(String email, String name) onAdd;
  const _PersonForm({required this.addLabel, required this.onAdd});

  @override
  State<_PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<_PersonForm> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _add() {
    final email = emailController.text;
    final name = nameController.text;
    if (email.contains('@')) {
      widget.onAdd(email, name);
    } else {
      Toast.warning(
        message: 'Please enter a valid email',
      );
      return;
    }
    nameController.clear();
    emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            keyboardAppearance: Brightness.dark,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            keyboardAppearance: Brightness.dark,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            decoration: const InputDecoration(
              hintText: 'Name (optional)',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: widget.addLabel,
            icon: Icons.add_rounded,
            onPressed: _add,
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final LumaPerson person;
  final VoidCallback onRemove;
  const _PersonTile({required this.person, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final hasName = person.name != null && person.name != '';
    final initial = (hasName ? person.name! : person.email).trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primary.withAlpha(40),
            child: Text(
              initial.isEmpty ? '?' : initial[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? person.name! : person.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasName)
                  Text(
                    person.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
