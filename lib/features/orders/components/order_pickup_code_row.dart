import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class OrderPickupCodeRow extends StatelessWidget {
  const OrderPickupCodeRow({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final chars = code.split("");
    return Row(
      children: [
        AppText.bold(
          "PICKUP\nCODE:",
          fontSize: 10,
          color: AppColors.mainBlack,
          letterSpacing: 0.7,
        ),
        Gap.w20,
        for (var i = 0; i < chars.length; i++) ...[
          if (i > 0) Gap.w4,
          Expanded(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffC8F7E0)),
                color: const Color(0xffFCFFFD),
              ),
              child: AppText.bold(
                chars[i],
                fontSize: 18,
                height: 1,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
