import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/components/text_field/gf_text_field_rounded.dart';
import 'package:podium/env.dart';
import 'package:podium/widgets/button/button.dart';

class CheerBooBottomSheet extends StatefulWidget {
  final bool isCheer;
  const CheerBooBottomSheet({required this.isCheer, Key? key})
      : super(key: key);

  @override
  State<CheerBooBottomSheet> createState() => _CheerBooBottomSheetState();
}

class _CheerBooBottomSheetState extends State<CheerBooBottomSheet> {
  String amount = Env.minimumCheerBooAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            widget.isCheer ? 'Cheer' : 'Boo',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          GFTextFieldRounded(
            editingbordercolor: Colors.grey,
            idlebordercolor: Colors.grey,
            borderwidth: 1,
            cornerradius: 8,
            keyboardAppearance: Brightness.dark,
            keyboardType: TextInputType.number,
            hintText: 'Amount',
            onChanged: (val) {
              setState(() {
                amount = val;
              });
            },
          ),
          const SizedBox(height: 20),
          Button(
            onPressed: () {
              Navigator.pop(context, amount);
            },
            text: 'Submit',
          )
        ],
      ),
    );
  }
}
