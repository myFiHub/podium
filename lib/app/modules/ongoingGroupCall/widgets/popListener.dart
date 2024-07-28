import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/app/routes/app_pages.dart';
import 'package:podium/utils/navigation/navigation.dart';
import 'package:podium/widgets/doubleTapWrapper.dart';

class PopListener extends StatelessWidget {
  final String warningMessage;
  const PopListener({super.key, required this.warningMessage});

  @override
  Widget build(BuildContext context) {
    return DoubleBackToCloseApp(
      snackBar: SnackBar(
        content: Text(
          warningMessage,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.red[300],
      ),
      child: SizedBox(),
      onPop: () {
        Navigate.to(
          type: NavigationTypes.offAllNamed,
          route: Routes.HOME,
        );
      },
    );
  }
}
