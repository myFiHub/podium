import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:podium/app/modules/global/lib/BlockChain.dart';
import 'package:podium/app/modules/ongoingOutpostCall/widgets/call_sheet.dart';
import 'package:podium/env.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/app_ui.dart';
import 'package:reown_appkit/reown_appkit.dart';

/// Asks for a cheer/boo amount; pops with the amount as a string.
class CheerBooBottomSheet extends StatefulWidget {
  final bool isCheer;
  const CheerBooBottomSheet({required this.isCheer, super.key});

  @override
  State<CheerBooBottomSheet> createState() => _CheerBooBottomSheetState();
}

class _CheerBooBottomSheetState extends State<CheerBooBottomSheet> {
  static final double _minimum = double.parse(Env.minimumCheerBooAmount);
  static final double _secondsPerMinimum =
      double.parse(Env.cheerBooTimeMultiplication);
  static const _presetMultipliers = [1, 2, 5, 10];

  late final _amount = TextEditingController(text: _format(_minimum));

  String get _currency =>
      ReownAppKitModalNetworks.getNetworkInfo(
        Env.chainNamespace,
        movementEVMChain.chainId,
      )?.currency ??
      '';

  Color get _color => widget.isCheer ? ColorName.success : ColorName.danger;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  static String _format(double value) {
    final text = value.toStringAsFixed(6);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _duration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    if (min == 0) return '$sec sec';
    return sec == 0 ? '$min min' : '$min min $sec sec';
  }

  double? get _value => double.tryParse(_amount.text.trim());

  bool get _valid {
    final value = _value;
    return value != null && value >= _minimum;
  }

  int get _seconds =>
      _valid ? ((_value! / _minimum) * _secondsPerMinimum).toInt() : 0;

  void _pick(double value) {
    HapticFeedback.selectionClick();
    final text = _format(value);
    _amount.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _submit() {
    if (!_valid) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, _amount.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cheer = widget.isCheer;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: CallSheet.maxHeight(context, 0.9)),
      child: CallSheet(
        title: cheer ? 'Cheer' : 'Boo',
        subtitle: cheer
            ? 'Tip to add to their talk time'
            : 'Pay to cut their talk time',
        icon: cheer
            ? Icons.celebration_rounded
            : Icons.sentiment_very_dissatisfied_rounded,
        iconColor: _color,
        child: SingleChildScrollView(
          child: ValueListenableBuilder(
            valueListenable: _amount,
            builder: (context, _, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _amountField(),
                const SizedBox(height: 12),
                _presets(),
                const SizedBox(height: 16),
                _preview(),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  label: cheer ? 'Send cheer' : 'Send boo',
                  icon: cheer
                      ? Icons.celebration_rounded
                      : Icons.thumb_down_alt_rounded,
                  color: _color,
                  onPressed: _valid ? _submit : null,
                ),
                const SizedBox(height: 10),
                Text(
                  'Every ${_format(_minimum)} $_currency '
                  '${cheer ? 'adds' : 'removes'} '
                  '${_duration(_secondsPerMinimum.toInt())}',
                  textAlign: TextAlign.center,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountField() {
    final invalid = _amount.text.trim().isNotEmpty && !_valid;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: _color.withAlpha(14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: invalid ? ColorName.danger : _color.withAlpha(90),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: TextField(
              controller: _amount,
              autofocus: true,
              keyboardAppearance: Brightness.dark,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
              ),
            ),
          ),
          Text(
            _currency,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _presets() {
    final current = _amount.text.trim();
    return Row(
      children: [
        for (final (i, multiplier) in _presetMultipliers.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _PresetChip(
              label: _format(_minimum * multiplier),
              selected: current == _format(_minimum * multiplier),
              color: _color,
              onTap: () => _pick(_minimum * multiplier),
            ),
          ),
        ],
      ],
    );
  }

  Widget _preview() {
    final cheer = widget.isCheer;
    final valid = _valid;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: child),
      ),
      child: valid
          ? Container(
              key: const ValueKey('effect'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  AppIconTile(
                    icon: cheer
                        ? Icons.more_time_rounded
                        : Icons.timer_off_outlined,
                    color: _color,
                    size: 40,
                    circle: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cheer ? '+' : '−'}${_duration(_seconds)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _color,
                          ),
                        ),
                        Text(
                          cheer
                              ? 'added to their talk time'
                              : 'taken from their talk time',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : AppCallout(
              key: const ValueKey('invalid'),
              text: 'Minimum is ${_format(_minimum)} $_currency',
              color: ColorName.warning,
            ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color.withAlpha(40) : AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? color.withAlpha(160) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? color : ColorName.white,
            ),
          ),
        ),
      ),
    );
  }
}
