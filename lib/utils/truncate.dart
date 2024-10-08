truncate(String text, {int length = 10}) {
  if (text.length <= length) {
    return text;
  }
  final half = length ~/ 2;
  return '${text.substring(0, half)}...${text.substring(text.length - half)}';
}
