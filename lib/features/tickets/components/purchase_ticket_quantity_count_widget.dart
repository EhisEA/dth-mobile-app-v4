import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";

class PurchaseTicketCountWidget extends StatelessWidget {
  const PurchaseTicketCountWidget({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.canIncrement = true,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool canIncrement;

  @override
  Widget build(BuildContext context) {
    final canDecrement = quantity > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PurchaseTicketCountButton(
          icon: Icons.remove,
          enabled: canDecrement,
          onTap: canDecrement ? onDecrement : null,
          backgroundColor: canDecrement ? AppColors.black : AppColors.tint5,
          iconColor: AppColors.white,
        ),
        SizedBox(
          width: 28,
          child: AppText.semiBold(
            "$quantity",
            fontSize: 14,
            color: AppColors.black,
            textAlign: TextAlign.center,
          ),
        ),
        PurchaseTicketCountButton(
          icon: Icons.add,
          enabled: canIncrement,
          onTap: canIncrement ? onIncrement : null,
          backgroundColor: canIncrement
              ? AppColors.primary
              : AppColors.greyTint30,
          iconColor: AppColors.white,
        ),
      ],
    );
  }
}

class PurchaseTicketCountButton extends StatelessWidget {
  const PurchaseTicketCountButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
