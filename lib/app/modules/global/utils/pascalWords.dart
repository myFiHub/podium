final pascalWords = RegExp(r"(?:[A-Z]+|^)[a-z]*");
String getPascalWords(String input) {
  final res = pascalWords.allMatches(input).map((m) => m[0]).toList();
  final list = res.where((element) => element != null).toList();
  return list.join(' ');
}
