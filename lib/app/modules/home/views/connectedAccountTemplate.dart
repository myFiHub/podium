import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/modules/global/controllers/global_controller.dart';
import 'package:podium/app/modules/global/widgets/session_widget.dart';
import 'package:web3modal_flutter/utils/util.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class HomeBody extends GetView<GlobalController> {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Obx(() {
      final initialized = controller.w3serviceInitialized.value;
      final service = controller.web3ModalService;
      return !initialized
          ? const SizedBox.shrink()
          : ConnectedBody(
              service: service,
            );
    }));
  }
}

class ConnectedBody extends GetWidget<GlobalController> {
  const ConnectedBody({super.key, required this.service});
// read service from the controller
  final W3MService service;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox.square(dimension: 4.0),
          _ButtonsView(w3mService: service),
          const Divider(height: 0.0, color: Colors.transparent),
          _ConnectedView(w3mService: service),
        ],
      ),
    );
  }
}

class _ButtonsView extends StatelessWidget {
  const _ButtonsView({required this.w3mService});
  final W3MService w3mService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AccountText(),
        const SizedBox.square(dimension: 8.0),
        W3MConnectWalletButton(
          service: w3mService,
          context: context,
        ),
        const SizedBox.square(dimension: 8.0),
      ],
    );
  }
}

class _ConnectedView extends StatelessWidget {
  const _ConnectedView({required this.w3mService});
  final W3MService w3mService;

  @override
  Widget build(BuildContext context) {
    if (!w3mService.isConnected) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: w3mService.balanceNotifier,
          builder: (_, balance, __) {
            return W3MAccountButton(
              service: w3mService,
              context: context,
            );
          },
        ),
        SessionWidget(w3mService: w3mService),
        const SizedBox.square(dimension: 12.0),
      ],
    );
  }
}

class AccountText extends GetWidget<GlobalController> {
  const AccountText({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final String? address = controller.connectedWalletAddress.value;
      return address == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                Util.truncate(
                  address,
                  length: 4,
                ),
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
            );
    });
  }
}
