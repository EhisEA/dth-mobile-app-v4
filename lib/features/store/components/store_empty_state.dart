import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreEmptyState extends StatelessWidget {
  const StoreEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            ImageAssets.storeEmptyState,
            height: 160,
            fit: BoxFit.contain,
          ),
          Gap.h16,
          AppText.medium(
            title,
            fontSize: 18,
            color: AppColors.black,
            textAlign: TextAlign.center,
          ),
          Gap.h8,
          AppText.regular(
            message,
            fontSize: 14,
            height: 1.4,
            color: AppColors.paleLavender,
            textAlign: TextAlign.center,
            multiText: true,
          ),
        ],
      ),
    );
  }
}
