import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/widgets/text/text.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSupportTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.greyTint15),
            ),
            child: Center(child: SvgPicture.asset(SvgAssets.backArrow)),
          ),
        ),
        Gap.w8,
        Expanded(
          child: AppTextField(
            hint: 'Search contents and events',
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            borderRadius: BorderRadius.circular(100),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            formatter: [FilteringTextInputFormatter.singleLineFormatter],
            hintStyle: AppTextStyle.regular.copyWith(
              color: AppColors.tint15,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
              maxHeight: 20,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SvgPicture.asset(
                SvgAssets.search,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.mainBlack,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        Gap.w12,
        GestureDetector(
          onTap: () {
            onSupportTap();
            HapticFeedback.lightImpact();
          },
          behavior: HitTestBehavior.opaque,
          child: SvgPicture.asset(SvgAssets.support),
        ),
      ],
    );
  }
}
