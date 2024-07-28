import 'package:flutter/material.dart';
import 'package:podium/widgets/doubleTapWrapper.dart';

class PopListener extends StatelessWidget {
  final String warningMessage;
  final void Function() onPop;
  const PopListener(
      {super.key, required this.warningMessage, required this.onPop});

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
        onPop();
      },
    );
  }
}
