import "package:dth_v4/widgets/text/app_text.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:flutter/material.dart";

/// Renders [text] with simple inline tags (stripped from output):
/// `<b>` bold, `<u>` underline, `<i>` / `<em>` italic. Case-insensitive;
/// supports nesting and combinations (e.g. `<b><u>x</u></b>`).
class InlineTaggedText extends StatelessWidget {
  const InlineTaggedText(
    this.text, {
    super.key,
    required this.color,
    this.strongColor,
    this.fontSize = 10,
    this.maxLines = 3,
    this.height = 1.35,
    this.textAlign,
  });

  final String text;
  final Color color;

  /// When set, `<b>...</b>` segments use this color (e.g. black on grey body).
  final Color? strongColor;
  final double fontSize;
  final int maxLines;
  final double height;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }
    final base = AppTextStyle.regular.copyWith(
      fontSize: fontSize,
      letterSpacing: -0.2,
      color: color,
      height: height,
    );

    final tagRe = RegExp(r"<\s*(/)?\s*(em|b|u|i)\s*>", caseSensitive: false);
    if (!tagRe.hasMatch(trimmed)) {
      return AppText.regular(
        trimmed,
        fontSize: fontSize,
        color: color,
        maxLines: maxLines,
        multiText: true,
        textAlign: textAlign,
      );
    }

    var boldDepth = 0;
    var underlineDepth = 0;
    var italicDepth = 0;

    TextStyle activeStyle() {
      var s = base;
      if (boldDepth > 0) {
        s = s.copyWith(fontWeight: FontWeight.w600);
        final sc = strongColor;
        if (sc != null) s = s.copyWith(color: sc);
      }
      if (italicDepth > 0) s = s.copyWith(fontStyle: FontStyle.italic);
      if (underlineDepth > 0) {
        s = s.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: s.color ?? color,
        );
      }
      return s;
    }

    void openTag(String tag) {
      switch (tag) {
        case "b":
          boldDepth++;
          break;
        case "u":
          underlineDepth++;
          break;
        case "i":
        case "em":
          italicDepth++;
          break;
      }
    }

    void closeTag(String tag) {
      switch (tag) {
        case "b":
          if (boldDepth > 0) boldDepth--;
          break;
        case "u":
          if (underlineDepth > 0) underlineDepth--;
          break;
        case "i":
        case "em":
          if (italicDepth > 0) italicDepth--;
          break;
      }
    }

    final children = <InlineSpan>[];
    var i = 0;

    for (final m in tagRe.allMatches(trimmed)) {
      if (m.start > i) {
        final t = trimmed.substring(i, m.start);
        if (t.isNotEmpty) {
          children.add(TextSpan(text: t, style: activeStyle()));
        }
      }
      final isClose = (m.group(1) ?? "").isNotEmpty;
      final tag = (m.group(2) ?? "").toLowerCase();
      if (isClose) {
        closeTag(tag);
      } else {
        openTag(tag);
      }
      i = m.end;
    }
    if (i < trimmed.length) {
      final t = trimmed.substring(i);
      if (t.isNotEmpty) {
        children.add(TextSpan(text: t, style: activeStyle()));
      }
    }

    if (children.isEmpty) {
      return AppText.regular(
        trimmed,
        fontSize: fontSize,
        color: color,
        maxLines: maxLines,
        multiText: true,
        textAlign: textAlign,
      );
    }

    return Text.rich(
      TextSpan(children: children),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );
  }
}
