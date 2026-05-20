import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class ShowAboutEventPanel extends StatelessWidget {
  const ShowAboutEventPanel({
    super.key,
    required this.aboutBody,
    required this.detailDate,
    required this.detailTime,
    required this.detailVenue,
  });

  final String aboutBody;
  final String detailDate;
  final String detailTime;
  final String detailVenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyTint15,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.semiBold(
            "About Event ",
            fontSize: 14,
            color: AppColors.black,
          ),
          Gap.h12,
          AppText.regular(
            aboutBody,
            fontSize: 12,
            color: AppColors.paleLavender,
            height: 1.45,
            multiText: true,
          ),
          Gap.h16,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailCell(label: "Date", value: detailDate),
              ),
              Gap.w8,
              Expanded(
                child: _DetailCell(label: "Time", value: detailTime),
              ),
            ],
          ),
          Gap.h16,
          _DetailCell(label: "Venue", value: detailVenue),
        ],
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.medium(label, fontSize: 12, color: AppColors.black),
        Gap.h4,
        AppText.regular(
          value,
          fontSize: 12,
          color: AppColors.paleLavender,
          maxLines: 4,
          multiText: true,
          height: 1.25,
        ),
      ],
    );
  }
}
