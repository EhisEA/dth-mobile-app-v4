import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/utils/colors.dart";
import "package:dth_v4/features/profile/bank_account/components/bank_account_card.dart";
import "package:dth_v4/widgets/text/app_text.dart";
import "package:flutter/material.dart";

/// Bank logo from [imageUrl], or initials fallback when null/empty/failed.
class BankLogoAvatar extends StatelessWidget {
  const BankLogoAvatar({
    super.key,
    required this.bankName,
    this.imageUrl,
    this.size = 40,
    this.fontSize = 14,
  });

  final String bankName;
  final String? imageUrl;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? "";
    final initials = BankAccountCard.bankInitials(bankName);

    Widget fallback() => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: AppText.bold(initials, fontSize: fontSize, color: AppColors.black),
    );

    if (url.isEmpty) return fallback();

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback(),
        errorWidget: (_, __, ___) => fallback(),
      ),
    );
  }
}
