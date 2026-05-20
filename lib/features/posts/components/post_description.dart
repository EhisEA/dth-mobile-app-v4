import "package:dth_v4/widgets/text/text.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

/// Up to two lines of body copy, then ellipsis and inline grey **Read more**.
class PostDescription extends StatefulWidget {
  const PostDescription({
    super.key,
    required this.text,
    this.onReadMore,
    this.bodyColor = const Color(0xff202020),
    this.linkColor = const Color(0xff6A6A6A),
  });

  final String text;
  final VoidCallback? onReadMore;
  final Color bodyColor;
  final Color linkColor;

  @override
  State<PostDescription> createState() => _PostDescriptionState();
}

class _PostDescriptionState extends State<PostDescription> {
  late TapGestureRecognizer _readMoreTap;

  @override
  void initState() {
    super.initState();
    _readMoreTap = TapGestureRecognizer()
      ..onTap = () => widget.onReadMore?.call();
  }

  @override
  void didUpdateWidget(covariant PostDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onReadMore != widget.onReadMore) {
      _readMoreTap.onTap = () => widget.onReadMore?.call();
    }
  }

  @override
  void dispose() {
    _readMoreTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = AppTextStyle.regular.copyWith(
      fontSize: 12,
      height: 1.4,
      color: widget.bodyColor,
    );
    final linkStyle = AppTextStyle.regular.copyWith(
      fontSize: 12,
      height: 1.4,
      color: widget.linkColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (widget.text.isEmpty) return const SizedBox.shrink();

        final fullPainter = TextPainter(
          text: TextSpan(text: widget.text, style: bodyStyle),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: w);

        if (!fullPainter.didExceedMaxLines) {
          return Text(widget.text, style: bodyStyle);
        }

        const suffix = '...';
        const linkText = ' Read more';
        int lo = 0;
        int hi = widget.text.length;
        while (lo < hi) {
          final mid = (lo + hi + 1) ~/ 2;
          final prefix = widget.text.substring(0, mid);
          final trial = TextPainter(
            text: TextSpan(
              style: bodyStyle,
              children: [
                TextSpan(text: '$prefix$suffix'),
                TextSpan(text: linkText, style: linkStyle),
              ],
            ),
            maxLines: 2,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: w);
          if (trial.didExceedMaxLines) {
            hi = mid - 1;
          } else {
            lo = mid;
          }
        }

        final cut = lo.clamp(0, widget.text.length);
        final visible = widget.text.substring(0, cut);

        return RichText(
          maxLines: 2,
          text: TextSpan(
            style: bodyStyle,
            children: [
              TextSpan(text: '$visible$suffix'),
              TextSpan(
                text: linkText,
                style: linkStyle,
                recognizer: _readMoreTap,
              ),
            ],
          ),
        );
      },
    );
  }
}
