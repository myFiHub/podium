import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost_ban.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// "5 minutes", "2 hours", "3 days" until [until], rounded up.
String formatTimeUntil(DateTime until) {
  final left = until.difference(DateTime.now());
  final minutes = (left.inSeconds / 60).ceil();
  if (minutes <= 1) return 'a minute';
  if (minutes < 120) return '$minutes minutes';
  final hours = (minutes / 60).ceil();
  if (hours < 48) return '$hours hours';
  return '${(hours / 24).ceil()} days';
}

bool _noticeOpen = false;

/// Tells the user a host removed or blocked them. Only one notice shows at a
/// time: a removal mid-call can arrive both as an event and as a refused
/// rejoin.
Future<void> showOutpostBanNotice(
  OutpostBanInfo ban, {
  String? outpostName,
}) async {
  if (_noticeOpen) return;
  _noticeOpen = true;
  final where = outpostName == null || outpostName.isEmpty
      ? 'this outpost'
      : outpostName;
  final until = ban.expiresAt;
  final isKick = ban.banKind == OutpostBanKind.kick && until != null;
  try {
    await Get.dialog<void>(
      AppDialog(
        icon: isKick ? Icons.logout_rounded : Icons.block_rounded,
        iconColor: AppColors.danger,
        title: isKick
            ? 'You were removed from the outpost'
            : "You're blocked from this outpost",
        message: isKick
            ? 'A host removed you from $where. '
                'You can join again in ${formatTimeUntil(until)}.'
            : "A host blocked you from $where. You can't join it unless a "
                'host lets you back in.',
        actions: [
          AppPrimaryButton(
            label: 'OK',
            onPressed: () => Get.closeOverlay(),
          ),
        ],
      ),
    );
  } finally {
    _noticeOpen = false;
  }
}
