import 'package:flutter/material.dart';
import 'package:podium/app/modules/myProfile/constants/connected_accounts_constants.dart';
import 'package:podium/utils/loginType.dart';
import 'package:podium/utils/styles.dart';

/// A widget that displays the currently logged-in account type with a success indicator.
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    super.key,
    required this.loginType,
  });

  final String loginType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ConnectedAccountsConstants.defaultPadding,
      decoration: BoxDecoration(
        color: ConnectedAccountsConstants.headerBackgroundColor
            .withAlpha(ConnectedAccountsConstants.headerBackgroundAlpha),
        borderRadius: ConnectedAccountsConstants.containerBorderRadius,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Success indicator',
            child: const Icon(
              Icons.check_circle,
              color: ConnectedAccountsConstants.successColor,
              size: ConnectedAccountsConstants.headerIconSize,
            ),
          ),
          space12,
          Expanded(
            child: Text(
              'Currently Logged in with ${loginTypeToDisplayName(loginType)}',
              style: const TextStyle(
                fontSize: ConnectedAccountsConstants.headerFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
