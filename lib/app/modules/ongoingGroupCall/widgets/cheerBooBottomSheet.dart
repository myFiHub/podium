import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/text_field/gf_text_field_rounded.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:web3modal_flutter/utils/w3m_chains_presets.dart';

class CheerBooBottomSheet extends StatefulWidget {
  final bool isCheer;
  const CheerBooBottomSheet({required this.isCheer, Key? key})
      : super(key: key);

  @override
  State<CheerBooBottomSheet> createState() => _CheerBooBottomSheetState();
}

class _CheerBooBottomSheetState extends State<CheerBooBottomSheet> {
  String amount = Env.minimumCheerBooAmount;
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: const BoxDecoration(
        color: ColorName.cardBackground,
        border: Border(
          top: BorderSide(
            color: ColorName.cardBorder,
            width: 1,
          ),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            widget.isCheer ? 'Cheer' : 'Boo',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          Input(
            keyboardAppearance: Brightness.dark,
            keyboardType: TextInputType.number,
            initialValue: Env.minimumCheerBooAmount,
            hintText: 'Amount',
            validator: (value) {
              try {
                int.parse(value ?? '0');
              } catch (e) {
                return 'Amount must be a number';
              }
              if (value!.isEmpty) {
                return 'Amount is required';
              }
              if (int.parse(value) < int.parse(Env.minimumCheerBooAmount)) {
                return 'Minimum amount is ${Env.minimumCheerBooAmount}';
              }
              return null;
            },
            onChanged: (val) {
              if (val.isNotEmpty) {
                setState(() {
                  amount = val;
                });
              } else {
                setState(() {
                  amount = Env.minimumCheerBooAmount;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          Button(
            type: ButtonType.gradient,
            onPressed: () {
              Navigator.pop(context, amount);
            },
            text: 'Submit',
          ),
          space10,
          space10,
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                  """each ${Env.minimumCheerBooAmount} ${W3MChainPresets.chains[Env.chainId]!.tokenName}, will ${widget.isCheer ? "add" : "reduce"} ${Env.cheerBooTimeMultiplication} seconds ${widget.isCheer ? "to" : "from"} 
                   that user's time""",
                  style: TextStyle(
                    fontSize: 16,
                    color: ColorName.greyText,
                    height: 2,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
