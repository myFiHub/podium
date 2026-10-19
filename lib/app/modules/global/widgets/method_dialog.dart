import 'dart:convert';

// import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:podium/app/modules/global/widgets/loading_widget.dart';
import 'package:podium/gen/colors.gen.dart';
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
      title: Text(
        widget.method,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: FutureBuilder<dynamic>(
        future: widget.response,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            final String t = jsonEncode(snapshot.data);
            debugPrint('[ExampleApp] result $t');
            return _ResultBox(text: t);
          } else if (snapshot.hasError) {
            return _ResultBox(
              text: snapshot.error.toString(),
              isError: true,
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

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFF04141) : ColorName.cardBorder;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError
              ? const Color(0xFFF04141).withAlpha(20)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(isError ? 90 : 255)),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontFamily: 'monospace',
              color: isError ? const Color(0xFFF04141) : ColorName.greyText,
            ),
          ),
        ),
      ),
    );
  }
}
