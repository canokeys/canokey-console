import 'dart:developer';

class MyStringUtils {
  static bool isFirstCapital(String string) {
    if (string.codeUnitAt(0) >= 65 && string.codeUnitAt(0) <= 90) {
      return true;
    }
    return false;
  }

  static bool isFirstLetter(String string) {
    if (string.codeUnitAt(0) >= 0 && string.codeUnitAt(0) <= 9) {
      return true;
    }
    return false;
  }

  static bool isAlphabetIncluded(String string) {
    string = string.toUpperCase();
    for (int i = 0; i < string.length; i++) {
      if (string.codeUnitAt(i) >= 65 && string.codeUnitAt(i) <= 90) {
        return true;
      }
    }
    return false;
  }

  static bool isDigitIncluded(String string) {
    for (int i = 0; i < string.length; i++) {
      if (string.codeUnitAt(i) >= 0 && string.codeUnitAt(i) <= 9) {
        return true;
      }
    }
    return false;
  }

  static bool isSpecialCharacterIncluded(String string) {
    String ch = "~`!@#\$%^&*.?_";

    for (int i = 0; i < string.length; i++) {
      if (ch.contains(string[i])) {
        return true;
      }
    }
    return false;
  }

  static bool isIncludedCharactersPresent(
      String string, List<String>? includeCharacters) {
    if (includeCharacters == null) {
      return false;
    }

    for (int i = 0; i < string.length; i++) {
      if (includeCharacters.contains(string[i])) {
        return true;
      }
    }
    return false;
  }

  static bool isIgnoreCharactersPresent(
      String string, List<String>? ignoreCharacters) {
    if (ignoreCharacters == null) {
      return false;
    }

    for (int i = 0; i < string.length; i++) {
      if (ignoreCharacters.contains(string[i])) {
        return true;
      }
    }
    return false;
  }

  static bool checkMaxAlphabet(String string, int maxAlphabet) {
    int counter = 0;
    string = string.toUpperCase();
    for (int i = 0; i < string.length; i++) {
      if (string.codeUnitAt(i) >= 65 && string.codeUnitAt(i) <= 90) {
        counter++;
      }
    }
    if (counter <= maxAlphabet) {
      return true;
    }
    return false;
  }

  static bool checkMaxDigit(String string, int maxDigit) {
    int counter = 0;

    for (int i = 0; i < string.length; i++) {
      if (string.codeUnitAt(i) >= 0 && string.codeUnitAt(i) <= 9) {
        counter++;
      }
    }
    if (counter <= maxDigit) {
      return true;
    }
    return false;
  }

  static bool checkMinAlphabet(String string, int minAlphabet) {
    int counter = 0;
    string = string.toUpperCase();
    for (int i = 0; i < string.length; i++) {
      if (string.codeUnitAt(i) >= 65 && string.codeUnitAt(i) <= 90) {
        counter++;
      }
    }
    if (counter >= minAlphabet) {
      return true;
    }
    return false;
  }

  static bool checkMinDigit(String string, int minDigit) {
    int counter = 0;
    for (int i = 0; i < string.length; i++) {
      if (string.codeUnitAt(i) >= 0 && string.codeUnitAt(i) <= 9) {
        counter++;
      }
    }
    if (counter >= minDigit) {
      return true;
    }
    return false;
  }

  static bool validateString(
    String string, {
    int minLength = 8,
    int maxLength = 20,
    bool firstCapital = false,
    bool firstDigit = false,
    bool includeDigit = false,
    bool includeAlphabet = false,
    bool includeSpecialCharacter = false,
    List<String>? includeCharacters,
    List<String>? ignoreCharacters,
    int minAlphabet = 5,
    int maxAlphabet = 20,
    int minDigit = 0,
    int maxDigit = 20,
  }) {
    if (string.length < minLength) {
      return false;
    }

    if (string.length > maxLength) {
      return false;
    }

    if (firstCapital && !isFirstCapital(string)) {
      return false;
    }

    if (firstDigit && !isFirstLetter(string)) {
      return false;
    }

    if (includeAlphabet && !isAlphabetIncluded(string)) {
      return false;
    }

    if (includeDigit && !isDigitIncluded(string)) {
      return false;
    }

    if (includeSpecialCharacter && !isSpecialCharacterIncluded(string)) {
      return false;
    }

    if (!isIncludedCharactersPresent(string, includeCharacters)) {
      return false;
    }

    if (isIgnoreCharactersPresent(string, ignoreCharacters)) {
      return false;
    }

    if (!checkMaxAlphabet(string, maxAlphabet)) {
      return false;
    }

    if (!checkMinAlphabet(string, minAlphabet)) {
      return false;
    }

    if (!checkMaxDigit(string, maxAlphabet)) {
      return false;
    }

    if (!checkMinDigit(string, minAlphabet)) {
      return false;
    }

    return true;
  }

  static bool isEmail(String email) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{1,}))$';
    RegExp regex = RegExp(pattern as String);
    log(regex.hasMatch(email).toString());
    return regex.hasMatch(email);
  }

  static bool validateStringRange(String text,
      [int minLength = 8, int maxLength = 20]) {
    return text.length >= minLength && text.length <= maxLength;
  }
}
