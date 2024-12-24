import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/env.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/utils/styles.dart';
import 'package:podium/widgets/button/button.dart';
import 'package:podium/widgets/textField/textFieldRounded.dart';
import 'package:reown_appkit/reown_appkit.dart';

class CheerBooBottomSheet extends StatefulWidget {
  final bool isCheer;
  const CheerBooBottomSheet({required this.isCheer, Key? key})
      : super(key: key);

  @override
  State<CheerBooBottomSheet> createState() => _CheerBooBottomSheetState();
}

final _formKey = GlobalKey<FormBuilderState>();

class _CheerBooBottomSheetState extends State<CheerBooBottomSheet> {
  String amount = '0';

  @override
  Widget build(BuildContext context) {
    String parsedValue = '';
    int calculatedSecondsToAdd = 0;
    final amountDouble = double.tryParse(amount);
    if (amount.isNotEmpty &&
        amountDouble != null &&
        amountDouble >= double.parse(Env.minimumCheerBooAmount)) {
      calculatedSecondsToAdd =
          ((amountDouble / double.parse(Env.minimumCheerBooAmount)) *
                  double.parse(Env.cheerBooTimeMultiplication))
              .toInt();
      // convert to min and sec
      final min = calculatedSecondsToAdd ~/ 60;
      final sec = calculatedSecondsToAdd % 60;
      parsedValue = 'will ${widget.isCheer ? "add" : "reduce"} $min min' +
          (sec > 0 ? ' $sec sec' : '') +
          ' to selected user\'s time';
    } else {
      parsedValue = 'enter a valid amount';
    }

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
      child: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              widget.isCheer ? 'Cheer' : 'Boo',
              style: const TextStyle(fontSize: 20),
            ),
            Container(
              height: 20,
              child: Text(
                parsedValue,
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorName.greyText,
                  height: 2,
                ),
              ),
            ),
            Container(
              height: 85,
              child: FormBuilderField(
                builder: (FormFieldState<String?> field) {
                  return Input(
                    keyboardAppearance: Brightness.dark,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    hintText: 'Amount (min: ${Env.minimumCheerBooAmount})',
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.min(
                          double.parse(Env.minimumCheerBooAmount),
                          errorText:
                              'Amount should be greater than ${Env.minimumCheerBooAmount}'),
                    ]),
                    onChanged: (value) {
                      setState(() {
                        amount = value;
                      });
                      field.didChange(value);
                      _formKey.currentState!.validate();
                    },
                  );
                },
                name: 'amount',
              ),
            ),
            Button(
              type: ButtonType.gradient,
              onPressed: () {
                if (_formKey.currentState!.saveAndValidate()) {
                  Navigator.pop(context, amount);
                }
              },
              text: 'Submit',
            ),
            space10,
            space10,
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                    // """each ${Env.minimumCheerBooAmount} ${ReownAppKitModalNetworks.getNetworkById(Env.chainNamespace, movementChain.chainId)!.currency}, will ${widget.isCheer ? "add" : "reduce"} ${Env.cheerBooTimeMultiplication} seconds ${widget.isCheer ? "to" : "from"}\nthat user's time""",
                    """each 0.1 ${ReownAppKitModalNetworks.getNetworkById(Env.chainNamespace, movementChain.chainId)!.currency}, will ${widget.isCheer ? "add" : "reduce"} 1 min ${widget.isCheer ? "to" : "from"}\nthat user's time""",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: ColorName.greyText,
                      height: 2,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
