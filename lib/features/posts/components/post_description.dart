import "package:dth_v4/widgets/text/text.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

/// Up to two lines of body copy, then ellipsis and inline **Read more**.
/// Tapping expands in place (and **Show less** collapses) unless [onReadMore]
/// is set, in which case the link delegates to that callback instead.
class PostDescription extends StatefulWidget {
  const PostDescription({
    super.key,
    required this.text,
    this.onReadMore,
    this.bodyColor = const Color(0xff202020),
    this.linkColor = const Color(0xff6A6A6A),
    this.lineHeight = 1.4,
  });

  final String text;
  final VoidCallback? onReadMore;
  final Color bodyColor;
  final Color linkColor;
  final double lineHeight;

  @override
  State<PostDescription> createState() => _PostDescriptionState();
}

class _PostDescriptionState extends State<PostDescription> {
  bool _expanded = false;
  late TapGestureRecognizer _toggleTap;

  @override
  void initState() {
    super.initState();
    _toggleTap = TapGestureRecognizer()..onTap = _onToggle;
  }

  @override
  void didUpdateWidget(covariant PostDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _expanded = false;
    }
  }

  @override
  void dispose() {
    _toggleTap.dispose();
    super.dispose();
  }

  void _onToggle() {
    if (widget.onReadMore != null) {
      widget.onReadMore!();
      return;
    }
    setState(() => _expanded = !_expanded);
  }

  TextStyle get _bodyStyle => AppTextStyle.regular.copyWith(
    fontSize: 12,
    height: widget.lineHeight,
    color: widget.bodyColor,
  );

  TextStyle get _linkStyle => AppTextStyle.regular.copyWith(
    fontSize: 12,
    height: widget.lineHeight,
    color: widget.linkColor,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (widget.text.isEmpty) return const SizedBox.shrink();

        if (_expanded) {
          return Text.rich(
            TextSpan(
              style: _bodyStyle,
              children: [
                TextSpan(text: widget.text),
                TextSpan(
                  text: " Show less",
                  style: _linkStyle,
                  recognizer: _toggleTap,
                ),
              ],
            ),
          );
        }

        final fullPainter = TextPainter(
          text: TextSpan(text: widget.text, style: _bodyStyle),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: w);

        if (!fullPainter.didExceedMaxLines) {
          return Text(widget.text, style: _bodyStyle);
        }

        const suffix = "...";
        const linkText = " Read more";
        var lo = 0;
        var hi = widget.text.length;
        while (lo < hi) {
          final mid = (lo + hi + 1) ~/ 2;
          final prefix = widget.text.substring(0, mid);
          final trial = TextPainter(
            text: TextSpan(
              style: _bodyStyle,
              children: [
                TextSpan(text: "$prefix$suffix"),
                TextSpan(text: linkText, style: _linkStyle),
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
            style: _bodyStyle,
            children: [
              TextSpan(text: "$visible$suffix"),
              TextSpan(
                text: linkText,
                style: _linkStyle,
                recognizer: _toggleTap,
              ),
            ],
          ),
        );
      },
    );
  }
}
