import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/wallet_controller.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const PageWrapper(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(title: 'Wallet', showBack: true),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: AppEmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet is working',
                      message: 'Your balances and activity will appear here.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
