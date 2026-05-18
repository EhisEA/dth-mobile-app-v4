import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/application_dashboard/applicant_dashboard.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_utils/flutter_utils.dart";

class ApplicantDashboardScrollBody extends StatelessWidget {
  const ApplicantDashboardScrollBody({
    super.key,
    required this.data,
    required this.viewModel,
  });

  final ApplicantDashboardData data;
  final ApplicantDashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final perf = data.performance;
    final arcColor = applicantPerformanceArcColor(perf.color);
    final caption = viewModel.performanceCaption(data);
    final journeyTitle = viewModel.journeySectionTitle(data);
    final rows = viewModel.journeyGridRows(data);

    return RefreshIndicator(
      onRefresh: viewModel.refreshDashboard,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        children: [
          Gap.h32,
          Gap.h32,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ApplicantPerformanceGauge(
              score: perf.score,
              max: perf.max,
              arcColor: arcColor,
              label: perf.label,
              caption: caption,
            ),
          ),
          if (data.banner != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(ImageAssets.applicantBanner),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data.banner!.title?.trim().isNotEmpty ?? false) ...[
                      AppText.semiBold(
                        data.banner!.title!.trim(),
                        fontSize: 14,
                        color: const Color(0xff38FF99),
                        multiText: true,
                      ),
                      if (data.banner!.body.trim().isNotEmpty) Gap.h4,
                    ],
                    if (data.banner!.body.trim().isNotEmpty)
                      AppText.regular(
                        data.banner!.body.trim(),
                        fontSize: 10,
                        color: AppColors.white,
                        multiText: true,
                      ),
                  ],
                ),
              ),
            ),
            Gap.h32,
          ],
          AppText.medium(journeyTitle, fontSize: 14, color: AppColors.black),
          Gap.h12,
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final cellWidth = (constraints.maxWidth - spacing) / 2;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var r = 0; r < rows.length; r++) ...[
                    if (r > 0) SizedBox(height: spacing),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: cellWidth,
                          child: ApplicantJourneyCard(
                            card: rows[r][0]!,
                            width: cellWidth,
                            ctaFetchBusy:
                                viewModel.interviewSlotsFetchBusyFor(
                                  rows[r][0]!.key,
                                ) ||
                                viewModel.interviewLinkFetchBusyFor(
                                  rows[r][0]!.key,
                                ),
                            scheduleFetchBusy: viewModel.scheduleFetchBusyFor(
                              rows[r][0]!.key,
                            ),
                            onCardTap:
                                rows[r][0]!.key.toLowerCase() == "schedule"
                                ? () => viewModel.openScheduleSheet(context)
                                : null,
                            onCta: (c) =>
                                viewModel.handleJourneyCta(context, c),
                          ),
                        ),
                        SizedBox(width: spacing),
                        SizedBox(
                          width: cellWidth,
                          child: rows[r][1] != null
                              ? ApplicantJourneyCard(
                                  card: rows[r][1]!,
                                  width: cellWidth,
                                  ctaFetchBusy:
                                      viewModel.interviewSlotsFetchBusyFor(
                                        rows[r][1]!.key,
                                      ) ||
                                      viewModel.interviewLinkFetchBusyFor(
                                        rows[r][1]!.key,
                                      ),
                                  scheduleFetchBusy: viewModel
                                      .scheduleFetchBusyFor(rows[r][1]!.key),
                                  onCardTap:
                                      rows[r][1]!.key.toLowerCase() ==
                                          "schedule"
                                      ? () =>
                                            viewModel.openScheduleSheet(context)
                                      : null,
                                  onCta: (c) =>
                                      viewModel.handleJourneyCta(context, c),
                                )
                              : SizedBox(width: cellWidth),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          if (data.footerBanner != null) ...[
            Gap.h12,
            ApplicantDashboardInlineBanner(
              banner: data.footerBanner!,
              backgroundColor: viewModel.bannerBackgroundForVariant(
                data.footerBanner!.variant,
              ),
              bodyColor: viewModel.bannerBodyTextColorForVariant(
                data.footerBanner!.variant,
              ),
              svg: viewModel.iconForVariant(data.footerBanner!.variant),
            ),
          ],
          Gap.h24,
          Gap.h32,
        ],
      ),
    );
  }
}
