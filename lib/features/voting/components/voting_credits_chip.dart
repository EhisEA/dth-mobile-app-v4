import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class VotingCreditsChip extends StatelessWidget {
  const VotingCreditsChip({
    super.key,
    required this.label,
    this.onTap,
    this.onAddTap,
    this.showAddIcon = false,
    this.showImage = true,
  });

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;
  final bool showAddIcon;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(SvgAssets.voteStar),
        Gap.w4,
        AppText.semiBold(label, fontSize: 12, color: const Color(0xff00AD55)),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showAddIcon ? 10 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        image: showImage
            ? const DecorationImage(
                image: AssetImage(ImageAssets.votingCreditsBg),
                fit: BoxFit.cover,
              )
            : null,
        color: showImage ? null : const Color(0xffFCFCFC),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAddIcon)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _wrapTap(onTap),
              child: labelRow,
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _wrapTap(onTap),
              child: labelRow,
            ),
          if (showAddIcon) ...[
            Gap.w4,
            _AddIconButton(onTap: _wrapTap(onAddTap ?? onTap)),
          ],
        ],
      ),
    );
  }

  VoidCallback? _wrapTap(VoidCallback? handler) {
    if (handler == null) return null;
    return () {
      HapticFeedback.lightImpact();
      handler();
    };
  }
}

class VotingCreditsAddButton extends StatelessWidget {
  const VotingCreditsAddButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: CircleAvatar(
        radius: 16.5,
        backgroundColor: const Color(0xff00AD55),
        child: Icon(Icons.add_rounded, size: 22, color: AppColors.white),
      ),
    );
  }
}

class _AddIconButton extends StatelessWidget {
  const _AddIconButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CircleAvatar(
        radius: 8.5,
        backgroundColor: const Color(0xff00AD55),
        child: Icon(Icons.add_rounded, size: 16, color: AppColors.white),
      ),
    );
  }
}
