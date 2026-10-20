import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/utils/outpost_moderation.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost_ban.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// What the host confirmed in [confirmOutpostBan].
typedef OutpostBanConfirmation = ({String? reason});

/// Warns the host what removing or blocking [name] does. Resolves to null
/// when they back out.
Future<OutpostBanConfirmation?> confirmOutpostBan({
  required String name,
  required OutpostBanKind kind,
  bool isCohost = false,
}) {
  return Get.dialog<OutpostBanConfirmation>(
    _OutpostBanDialog(name: name, kind: kind, isCohost: isCohost),
    barrierDismissible: false,
  );
}

class _OutpostBanDialog extends StatefulWidget {
  final String name;
  final OutpostBanKind kind;
  final bool isCohost;
  const _OutpostBanDialog({
    required this.name,
    required this.kind,
    required this.isCohost,
  });

  @override
  State<_OutpostBanDialog> createState() => _OutpostBanDialogState();
}

class _OutpostBanDialogState extends State<_OutpostBanDialog> {
  final _reason = TextEditingController();

  bool get _isBlock => widget.kind == OutpostBanKind.ban;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = kickDuration.inMinutes;
    return AppDialog(
      icon: _isBlock ? Icons.block_rounded : Icons.person_remove_rounded,
      iconColor: AppColors.danger,
      urgent: true,
      title: _isBlock
          ? 'Block ${widget.name} from this outpost?'
          : 'Remove ${widget.name}?',
      message: _isBlock
          ? "They'll be disconnected right away and can't join this outpost "
              'again until a host unblocks them. They also stop being a '
              'member, so they lose its reminders.'
          : "They'll be disconnected right away and can't rejoin for "
              '$minutes minutes. They stay a member of the outpost.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isCohost) ...[
            AppCallout(
              icon: Icons.shield_outlined,
              color: AppColors.danger,
              text: _isBlock
                  ? '${widget.name} is a cohost. Blocking them also takes '
                      'away their cohost role.'
                  : '${widget.name} is a cohost and keeps that role.',
            ),
            const SizedBox(height: 12),
          ],
          if (_isBlock) ...[
            TextField(
              controller: _reason,
              keyboardAppearance: Brightness.dark,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                helperText: 'Only hosts can see this',
                counterText: '',
              ),
            ),
          ],
        ],
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancel',
          onPressed: () => Get.closeOverlay(),
        ),
        AppPrimaryButton(
          label: _isBlock ? 'Block' : 'Remove',
          color: AppColors.danger,
          onPressed: () => Get.closeOverlay<OutpostBanConfirmation>(
            result: (reason: _isBlock ? _reason.text.trim() : null),
          ),
        ),
      ],
    );
  }
}
