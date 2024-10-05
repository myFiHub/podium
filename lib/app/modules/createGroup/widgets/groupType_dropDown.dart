import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/gen/colors.gen.dart';

class DropDownItem {
  final String value;
  final String text;
  final bool? enabled;

  DropDownItem({
    required this.value,
    required this.text,
    this.enabled,
  });
}

class DropDown extends StatelessWidget {
  final List<DropDownItem> items;
  final String selectedValue;
  final Function(String) onChanged;
  const DropDown({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Row(
          children: [
            SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                'Room Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorName.greyText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        items: items
            .map((DropDownItem item) => DropdownMenuItem<String>(
                  value: item.value,
                  enabled: item.enabled ?? true,
                  child: Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 16,
                      // fontWeight: FontWeight.bold,
                      color: item.enabled == false ? Colors.grey : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        value: selectedValue,
        onChanged: (value) {
          onChanged(value!);
        },
        buttonStyleData: ButtonStyleData(
          height: 55,
          width: Get.width - 20,
          padding: const EdgeInsets.only(left: 14, right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ColorName.cardBorder,
            ),
            color: ColorName.cardBackground,
          ),
          elevation: 0,
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.arrow_forward_ios_outlined,
          ),
          iconSize: 14,
          iconEnabledColor: ColorName.greyText,
          iconDisabledColor: Colors.grey,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 220,
          width: Get.width - 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: ColorName.cardBackground,
          ),
          // offset: const Offset(-10, 0),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(8),
            thickness: WidgetStateProperty.all(6),
            thumbVisibility: WidgetStateProperty.all(true),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
      ),
    );
  }
}
