import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:podium/root.dart';
import 'package:podium/widgets/ui/app_ui.dart';

import '../controllers/playground_controller.dart';

const platform = const MethodChannel('flutter.native/helper');

class PlaygroundView extends GetView<PlaygroundController> {
  const PlaygroundView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppPageHeader(title: 'Playground', showBack: true),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('NATIVE CHANNEL', style: AppText.label),
                          const SizedBox(height: 6),
                          const Text(
                            'Call the native helper to change the color.',
                            style: AppText.muted,
                          ),
                          const SizedBox(height: 16),
                          AppPrimaryButton(
                            onPressed: () {
                              changeColor("red");
                            },
                            icon: Icons.palette_outlined,
                            label: 'Change color',
                          ),
                        ],
                      ),
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

Future<String> changeColor(String color) async {
  try {
    final String result = await platform.invokeMethod("changeColor", {
      "color": color,
    });
    print('RESULT -> $result');
    color = result;
  } on PlatformException catch (e) {
    print(e);
  }
  return color;
}
