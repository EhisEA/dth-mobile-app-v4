import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/widgets/text/text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BookedShowDescription extends StatefulWidget {
  const BookedShowDescription({super.key, required this.text, this.onReadMore});

  final String text;
  final VoidCallback? onReadMore;

  @override
  State<BookedShowDescription> createState() => _BookedShowDescriptionState();
}

class _BookedShowDescriptionState extends State<BookedShowDescription> {
  static const String _ellipsis = "\u2026";

  late final TapGestureRecognizer _readMoreTap = TapGestureRecognizer()
    ..onTap = _handleReadMore;

  TextStyle get _bodyStyle => AppTextStyle.regular.copyWith(
    fontSize: 12,
    height: 1.35,
    color: AppColors.paleLavender,
  );

  TextStyle get _linkStyle => AppTextStyle.medium.copyWith(
    fontSize: 12,
    height: 1.35,
    color: AppColors.tint15,
  );

  void _handleReadMore() => widget.onReadMore?.call();

  @override
  void didUpdateWidget(covariant BookedShowDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readMoreTap.onTap = _handleReadMore;
  }

  @override
  void dispose() {
    _readMoreTap.dispose();
    super.dispose();
  }

  bool _fitsTwoLines(InlineSpan span, double maxWidth, TextDirection dir) {
    final tp = TextPainter(text: span, textDirection: dir, maxLines: 2)
      ..layout(maxWidth: maxWidth);
    return !tp.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final onReadMore = widget.onReadMore;
    final dir = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final bodyStyle = _bodyStyle;
        final linkStyle = _linkStyle;

        if (!maxW.isFinite || maxW <= 0 || text.isEmpty) {
          return Text(
            text,
            style: bodyStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }

        final plain = TextPainter(
          text: TextSpan(text: text, style: bodyStyle),
          textDirection: dir,
          maxLines: 2,
        )..layout(maxWidth: maxW);

        if (!plain.didExceedMaxLines) {
          return Text(
            text,
            style: bodyStyle,
            maxLines: 2,
            overflow: TextOverflow.clip,
          );
        }

        if (onReadMore == null) {
          return Text(
            text,
            style: bodyStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }

        InlineSpan spanForPrefix(int len) {
          final prefix = text.substring(0, len);
          return TextSpan(
            style: bodyStyle,
            children: [
              TextSpan(text: prefix),
              TextSpan(text: _ellipsis, style: bodyStyle),
              TextSpan(
                text: " Read more",
                style: linkStyle,
                recognizer: _readMoreTap,
              ),
            ],
          );
        }

        var lo = 0;
        var hi = text.length;
        while (lo < hi) {
          final mid = (lo + hi + 1) ~/ 2;
          if (_fitsTwoLines(spanForPrefix(mid), maxW, dir)) {
            lo = mid;
          } else {
            hi = mid - 1;
          }
        }

        final best = lo.clamp(0, text.length);
        final prefix = text.substring(0, best);

        return Text.rich(
          TextSpan(
            style: bodyStyle,
            children: [
              TextSpan(text: prefix),
              TextSpan(text: _ellipsis, style: bodyStyle),
              TextSpan(
                text: " Read more",
                style: linkStyle,
                recognizer: _readMoreTap,
              ),
            ],
          ),
          maxLines: 2,
        );
      },
    );
  }
}
