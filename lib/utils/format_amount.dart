/// `4 MOVE`, `0.0125 AVAX`: no trailing zeros, at most 4 decimals.
String formatAmount(num amount, String currency) {
  final text = amount.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  return '$text $currency';
}
