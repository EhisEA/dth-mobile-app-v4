import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class StatsPill extends StatelessWidget {
  const StatsPill({super.key, this.icon, this.iconData, required this.label})
    : assert(icon != null || iconData != null);

  final String? icon;
  final IconData? iconData;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            SvgPicture.asset(
              icon!,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                AppColors.paleLavender,
                BlendMode.srcIn,
              ),
            )
          else
            Icon(iconData, size: 18, color: AppColors.paleLavender),
          Gap.w6,
          Flexible(
            child: AppText.regular(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.paleLavender,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
