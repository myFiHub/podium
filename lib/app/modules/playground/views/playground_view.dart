import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:podium/widgets/button/button.dart';

import '../controllers/playground_controller.dart';

const platform = const MethodChannel('flutter.native/helper');

class PlaygroundView extends GetView<PlaygroundController> {
  const PlaygroundView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Button(
          onPressed: () {
            changeColor("red");
          },
          text: "change color",
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
