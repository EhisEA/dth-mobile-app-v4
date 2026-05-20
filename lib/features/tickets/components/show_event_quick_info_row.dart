import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ShowEventQuickInfoRow extends StatelessWidget {
  const ShowEventQuickInfoRow({
    super.key,
    required this.location,
    required this.dateTimeLine,
  });

  final String location;
  final String dateTimeLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          SvgAssets.location,
          width: 12,
          height: 12,
          colorFilter: ColorFilter.mode(AppColors.blackTint20, BlendMode.srcIn),
        ),
        Gap.w4,
        Flexible(
          child: AppText.regular(
            location,
            fontSize: 12,
            color: AppColors.blackTint20,
            maxLines: 1,
          ),
        ),
        Gap.w8,
        Row(
          children: [
            SvgPicture.asset(
              SvgAssets.clockOutline,
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(
                AppColors.blackTint20,
                BlendMode.srcIn,
              ),
            ),
            Gap.w4,
            AppText.regular(
              dateTimeLine,
              fontSize: 12,
              color: AppColors.blackTint20,
            ),
          ],
        ),
      ],
    );
  }
}
