import 'package:flutter/material.dart';
import 'package:podium/app/modules/myProfile/constants/connected_accounts_constants.dart';
import 'package:podium/utils/truncate.dart';

/// A widget that displays a truncated identifier with consistent styling.
class IdentifierText extends StatelessWidget {
  const IdentifierText({
    super.key,
    required this.identifier,
  });

  final String? identifier;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Account identifier',
      child: Text(
        identifier != null ? truncate(identifier!) : '',
        style: const TextStyle(
          fontSize: ConnectedAccountsConstants.identifierFontSize,
          color: ConnectedAccountsConstants.identifierColor,
        ),
      ),
    );
  }
}
