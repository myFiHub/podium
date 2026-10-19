import 'package:flutter/material.dart';
import 'package:podium/app/modules/myProfile/constants/connected_accounts_constants.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// A widget that displays the currently logged-in account type with a success indicator.
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    super.key,
    required this.loginType,
  });

  final String loginType;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: ConnectedAccountsConstants.headerBackgroundColor
          .withAlpha(ConnectedAccountsConstants.headerBackgroundAlpha),
      borderColor: ConnectedAccountsConstants.successColor.withAlpha(70),
      child: Row(
        children: [
          Semantics(
            label: 'Success indicator',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ConnectedAccountsConstants.successColor.withAlpha(36),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: ConnectedAccountsConstants.successColor,
                size: ConnectedAccountsConstants.headerIconSize,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Currently logged in with', style: AppText.caption),
                const SizedBox(height: 2),
                Text(
                  loginTypeToDisplayName(loginType),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: ConnectedAccountsConstants.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
