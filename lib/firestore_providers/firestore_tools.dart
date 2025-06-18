import 'package:diacritic/diacritic.dart';

String searchify(String str) {
  return removeDiacritics(
    str
        .toLowerCase()
        .replaceAll(" ", "")
        .replaceAll("0", "zero")
        .replaceAll("1", "one")
        .replaceAll("2", "two")
        .replaceAll("3", "three")
        .replaceAll("4", "four")
        .replaceAll("5", "five")
        .replaceAll("6", "six")
        .replaceAll("7", "seven")
        .replaceAll("8", "eight")
        .replaceAll("9", "nine"),
  );
}
