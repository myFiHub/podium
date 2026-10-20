import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/checkTicket/controllers/checkTicket_controller.dart';
import 'package:podium/app/modules/checkTicket/views/checkTicket_view.dart';
import 'package:podium/app/modules/createOutpost/outpost_types.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/utils/easyStore.dart';
import 'package:podium/data/repositories/repositories.dart';
import 'package:podium/providers/api/api.dart';
import 'package:podium/providers/api/podium/models/outposts/outpost.dart';
import 'package:podium/providers/api/podium/models/users/user.dart';
import 'package:podium/services/toast/toast.dart';
import 'package:podium/utils/logger.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// The checks between tapping an outpost and opening it: who may enter and
/// speak (prompting for tickets when needed) and the 18+ confirmation.
class JoinOutpostFlow {
  final _userRepository = Get.find<UserRepository>();

  static final _noAccess = OutpostAccesses(canEnter: false, canSpeak: false);

  Future<OutpostAccesses> getOutpostAccesses({
    required OutpostModel outpost,
    bool joiningByLink = false,
  }) async {
    final fullAccess = OutpostAccesses(canEnter: true, canSpeak: true);
    if (outpost.creator_user_uuid == myId) return fullAccess;
    if (outpost.is_archived) {
      Toast.error(message: "This Outpost is archived");
      return _noAccess;
    }
    if ((outpost.cohost_user_uuids ?? []).contains(myId)) return fullAccess;
    if (await _isOnLumaGuestList(outpost)) return fullAccess;

    final evaluator = TicketAccessEvaluator(
      outpost,
      myId: myId,
      joiningByLink: joiningByLink,
    );
    if (evaluator.isAccessBuyable || evaluator.isSpeakBuyable) {
      final accesses = await _checkTicket(
        outpost: outpost,
        joiningByLink: joiningByLink,
      );
      if (accesses?.canEnter == false) {
        Toast.error(message: "You need a ticket to join this Outpost");
      }
      return accesses ?? _noAccess;
    }

    if (evaluator.canEnterWithoutTicket) {
      return OutpostAccesses(
        canEnter: true,
        canSpeak: evaluator.canSpeakWithoutTicket,
      );
    }
    Toast.error(
      message: switch (outpost.enter_type) {
        FreeOutpostAccessTypes.onlyLink =>
          "This is a private Outpost, you need an invite link to join",
        FreeOutpostAccessTypes.invited_users =>
          "You need an invite to join this Outpost",
        _ => "You don't have access to this Outpost",
      },
    );
    return _noAccess;
  }

  /// Luma guests and hosts signed in with the same email get full access.
  Future<bool> _isOnLumaGuestList(OutpostModel outpost) async {
    final eventId = outpost.luma_event_id;
    final loginType = myUser.login_type;
    if (eventId == null || eventId.isEmpty || loginType == null) return false;
    if (!loginType.contains('google') && !loginType.contains('email')) {
      return false;
    }
    try {
      final (guests, event) = await (
        HttpApis.lumaApi.getGuests(eventId: eventId),
        HttpApis.lumaApi.getEvent(eventId: eventId),
      ).wait;
      final email = myUser.email;
      return guests.any((e) => e.guest.user_email == email) ||
          (event?.hosts ?? []).any((h) => h.email == email);
    } catch (e) {
      l.e(e);
      return false;
    }
  }

  /// Shows the ticket sheet unless every ticket is already held.
  Future<OutpostAccesses?> _checkTicket({
    required OutpostModel outpost,
    required bool joiningByLink,
  }) async {
    final ticketCheck = CheckticketController()
      ..outpost.value = outpost
      ..joiningByLink = joiningByLink;
    final accesses = await ticketCheck.checkTickets();
    if (accesses.canEnter && accesses.canSpeak) return accesses;
    return Get.dialog<OutpostAccesses?>(
      AppDialogMotion(child: CheckTicketView(controller: ticketCheck)),
    );
  }

  /// Resolves true when the outpost has no adult content, the user already
  /// confirmed their age, or they confirm it now.
  Future<bool> confirmAge({
    required OutpostModel outpost,
    required UserModel myUser,
  }) async {
    final iAmOwner = outpost.creator_user_uuid == myUser.uuid;
    if (outpost.i_am_member ||
        iAmOwner ||
        !outpost.has_adult_content ||
        myUser.is_over_18 == true) {
      return true;
    }

    final result = await Get.dialog(
      AppDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.accent,
        title: "Age Verification Required",
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Adult Content Warning", style: AppText.cardTitle),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "You must be 18+ to access this content",
                    style: AppText.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const AppCallout(
              text:
                  "By proceeding, you confirm that you are at least 18 years of age.",
              icon: Icons.verified_user_outlined,
            ),
          ],
        ),
        stackActions: true,
        actions: [
          AppPrimaryButton(
            label: "Yes, I'm 18 or older",
            color: AppColors.accent,
            foreground: AppColors.onColor(AppColors.accent),
            onPressed: () {
              Get.find<GlobalController>().setIsMyUserOver18(true);
              _userRepository.updateMyUserData({'is_over_18': true});
              Navigator.of(Get.overlayContext!).pop(true);
            },
          ),
          AppSecondaryButton(
            label: "No, I'm under 18",
            onPressed: () {
              Navigator.of(Get.overlayContext!).pop(false);
            },
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
