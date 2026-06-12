import "package:dth_v4/data/data.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Header row shown above a list of comments or replies — title + count on
/// the left, sort dropdown on the right. Used by both the post detail
/// comments section and the comment thread replies section.
class CommentSortHeader extends StatelessWidget {
  const CommentSortHeader({
    super.key,
    required this.title,
    required this.count,
    required this.sort,
    required this.onSortChanged,
  });

  final String title;
  final int count;
  final CommentSort sort;
  final void Function(CommentSort) onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AppText.semiBold(
              title,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0XFF202020),
            ),
            Gap.w8,
            AppText.regular("$count", fontSize: 12, color: Color(0XFF8F8F8F)),
          ],
        ),
        PopupMenuButton<CommentSort>(
          initialValue: sort,
          onSelected: onSortChanged,
          tooltip: "Sort",
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: CommentSort.latest,
              child: Text("Most recent"),
            ),
            PopupMenuItem(value: CommentSort.oldest, child: Text("Oldest")),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.regular(
                sort == CommentSort.latest ? "Most recent" : "Oldest",
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0XFF454545),
              ),
              Gap.w2,
              const Icon(Icons.expand_more, size: 14, color: Color(0XFF454545)),
            ],
          ),
        ),
      ],
    );
  }
}
