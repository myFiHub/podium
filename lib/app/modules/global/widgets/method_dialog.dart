import 'dart:convert';

// import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/utils/constants.dart';

class MethodDialog extends StatefulWidget {
  static Future<void> show(
    BuildContext context,
    String method,
    Future<dynamic> response,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return MethodDialog(
          method: method,
          response: response,
        );
      },
    );
  }

  const MethodDialog({
    super.key,
    required this.method,
    required this.response,
  });

  final String method;
  final Future<dynamic> response;

  @override
  MethodDialogState createState() => MethodDialogState();
}

class MethodDialogState extends State<MethodDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.method),
      content: FutureBuilder<dynamic>(
        future: widget.response,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            final String t = jsonEncode(snapshot.data);
            debugPrint('[ExampleApp] result $t');
            return InkWell(
              // onTap: () => _copyToClipboard(t),
              child: Text(t),
            );
          } else if (snapshot.hasError) {
            return InkWell(
              // onTap: () => _copyToClipboard(snapshot.data.toString()),
              child: Text(snapshot.error.toString()),
            );
          } else {
            return const SizedBox(
              width: StyleConstants.linear48,
              height: StyleConstants.linear48,
              child: Center(
                child: LoadingWidget(),
              ),
            );
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            StringConstants.close,
          ),
        ),
      ],
    );
  }
}
