import "package:dth_v4/core/extension/double_extension.dart";

extension StringExtension on String {
  /// Removes a dangling emoji joiner left behind when a grapheme-cluster
  /// truncation splits a composite emoji — a trailing Zero-Width Joiner
  /// (U+200D), variation selector (U+FE0F/U+FE0E), or a lone regional-indicator
  /// half of a flag. Such fragments render as "?"/tofu (notably in truncated
  /// "Read more" text on some OS versions); the base emoji left after trimming
  /// renders fine. Uses only `runes`, so it needs no extra imports.
  String trimDanglingEmojiJoiner() {
    bool isJoiner(int r) => r == 0x200D || r == 0xFE0F || r == 0xFE0E;
    bool isRegional(int r) => r >= 0x1F1E6 && r <= 0x1F1FF;

    final codepoints = runes.toList();
    var end = codepoints.length;

    // Drop trailing joiners / variation selectors (keep the base they dangled
    // from — a standalone base emoji renders correctly).
    while (end > 0 && isJoiner(codepoints[end - 1])) {
      end--;
    }

    // A flag is two regional indicators; an odd trailing run means we split one.
    var regionalRun = 0;
    for (var i = end - 1; i >= 0 && isRegional(codepoints[i]); i--) {
      regionalRun++;
    }
    if (regionalRun.isOdd) end--;

    if (end == codepoints.length) return this;
    return String.fromCharCodes(codepoints.sublist(0, end));
  }

  ///check if the string is an email
  bool isEmail() {
    //email regex pattern
    final String emmailRegExpString =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

    final RegExp emmailRegExp = RegExp(emmailRegExpString);
    return emmailRegExp.hasMatch(this);
  }

  ///check if the string is a web link
  bool isLink() {
    //email regex pattern
    final String linkRegExpString =
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?";
    final RegExp linkRegExp = RegExp(linkRegExpString);
    return linkRegExp.hasMatch(this);
  }

  /// this would capitalize the first letter of the String
  String capitalize({dynamic lowercaseOther = false}) {
    final String text = this;
    return "${text[0].toUpperCase()}${lowercaseOther == true ? text.substring(1).toLowerCase() : text.substring(1).toLowerCase()}";
  }

  String toMoney() {
    return double.parse(replaceAll(",", "")).toMoneyWholeNumber();
  }

  String toMoneyDecimal() {
    return double.parse(replaceAll(",", "")).toMoney(truncate: true);
  }

  String shorten({int start = 6, int end = 4}) {
    if (length <= start + end) return this;
    return "${substring(0, start)}......${substring(length - end)}";
  }

  String shorten2({int start = 6, int end = 4}) {
    if (length <= start + end) return this;
    return "${substring(0, start)}****${substring(length - end)}";
  }

  String toMoneyCrypto() {
    return double.parse(replaceAll(",", "")).toMoney();
  }

  bool get isImage {
    try {
      final extensions = ["png", "jpg", "jpeg", "heic", "gif"];
      return extensions.contains(split(".").last.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  bool get isDoc {
    try {
      final extensions = ["doc", "docx", "pdf"];
      return extensions.contains(split(".").last.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  bool get isAudio {
    try {
      final extensions = ["mp3"];
      return extensions.contains(split(".").last.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  bool get isVideo {
    try {
      final extensions = ["mp4", "mov"];
      return extensions.contains(split(".").last.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  String formatAmount2(
    // String amount,
  ) {
    final String amount = this;
    // Remove any commas or other non-digit characters except decimal point and minus
    final String cleanedAmount = amount.replaceAll(RegExp(r"[^\d.-]"), "");

    // Try to parse the string to a number
    final num? numericAmount = num.tryParse(cleanedAmount);

    // If parsing fails, return the original string or handle error
    if (numericAmount == null) {
      return amount; // or throw Exception('Invalid amount format: $amount');
    }

    if (numericAmount == 0) return "0";

    final absAmount = numericAmount.abs();
    const units = [
      "",
      "K",
      "MILLION",
      "BILLION",
      "TRILLION",
    ]; // Add more units if needed

    // Find the appropriate unit
    int unitIndex = 0;
    double scaledAmount = absAmount.toDouble();

    while (scaledAmount >= 1000 && unitIndex < units.length - 1) {
      scaledAmount /= 1000;
      unitIndex++;
    }

    // Format the number based on its size
    String formattedNumber;
    if (scaledAmount < 10) {
      // For numbers 1-9.99, show up to 2 decimal places
      formattedNumber = scaledAmount.toStringAsFixed(
        scaledAmount.truncateToDouble() == scaledAmount ? 0 : 2,
      );
    } else if (scaledAmount < 100) {
      // For numbers 10-99.99, show up to 1 decimal place
      formattedNumber = scaledAmount.toStringAsFixed(
        scaledAmount.truncateToDouble() == scaledAmount ? 0 : 1,
      );
    } else {
      // For numbers 100-999, show as integer
      formattedNumber = scaledAmount.toStringAsFixed(0);
    }

    // Remove trailing .0 if present
    if (formattedNumber.endsWith(".0")) {
      formattedNumber = formattedNumber.substring(
        0,
        formattedNumber.length - 2,
      );
    }
    if (formattedNumber.endsWith(".00")) {
      formattedNumber = formattedNumber.substring(
        0,
        formattedNumber.length - 3,
      );
    }

    // Handle negative numbers
    if (numericAmount < 0) {
      formattedNumber = "-$formattedNumber";
    }

    return "$formattedNumber${units[unitIndex]}";
  }

  String formatAmount(
    // String amount,
  ) {
    final String amount = this;
    // Remove any commas or other non-digit characters except decimal point and minus
    final String cleanedAmount = amount.replaceAll(RegExp(r"[^\d.-]"), "");

    // Try to parse the string to a number
    final num? numericAmount = num.tryParse(cleanedAmount);

    // If parsing fails, return the original string or handle error
    if (numericAmount == null) {
      return amount; // or throw Exception('Invalid amount format: $amount');
    }

    if (numericAmount == 0) return "0";

    final absAmount = numericAmount.abs();
    const units = ["", "k", "M", "b", "t"]; // Add more units if needed

    // Find the appropriate unit
    int unitIndex = 0;
    double scaledAmount = absAmount.toDouble();

    while (scaledAmount >= 1000 && unitIndex < units.length - 1) {
      scaledAmount /= 1000;
      unitIndex++;
    }

    // Format the number based on its size
    String formattedNumber;
    if (scaledAmount < 10) {
      // For numbers 1-9.99, show up to 2 decimal places
      formattedNumber = scaledAmount.toStringAsFixed(
        scaledAmount.truncateToDouble() == scaledAmount ? 0 : 2,
      );
    } else if (scaledAmount < 100) {
      // For numbers 10-99.99, show up to 1 decimal place
      formattedNumber = scaledAmount.toStringAsFixed(
        scaledAmount.truncateToDouble() == scaledAmount ? 0 : 1,
      );
    } else {
      // For numbers 100-999, show as integer
      formattedNumber = scaledAmount.toStringAsFixed(0);
    }

    // Remove trailing .0 if present
    if (formattedNumber.endsWith(".0")) {
      formattedNumber = formattedNumber.substring(
        0,
        formattedNumber.length - 2,
      );
    }
    if (formattedNumber.endsWith(".00")) {
      formattedNumber = formattedNumber.substring(
        0,
        formattedNumber.length - 3,
      );
    }

    // Handle negative numbers
    if (numericAmount < 0) {
      formattedNumber = "-$formattedNumber";
    }

    return "$formattedNumber${units[unitIndex]}";
  }
}
