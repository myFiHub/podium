import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:podium/utils/palette.dart';

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
        hint: Row(
          children: [
            const SizedBox(
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
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: item.enabled == false
                          ? ColorName.secondaryText
                          : ColorName.white,
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
          height: 50,
          padding: const EdgeInsets.only(left: 14, right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ColorName.cardBorder,
            ),
            color: ColorName.white.withAlpha(10),
          ),
          elevation: 0,
        ),
        iconStyleData: IconStyleData(
          icon: const Icon(
            Icons.expand_more_rounded,
          ),
          iconSize: 20,
          iconEnabledColor: ColorName.greyText,
          iconDisabledColor: ColorName.secondaryText,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 220,
          offset: const Offset(0, -6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: ColorName.cardBackground,
            border: Border.all(color: ColorName.cardBorder),
          ),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(8),
            thickness: WidgetStateProperty.all(4),
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
