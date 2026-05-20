import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/application_dashboard/applicant_dashboard.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class ApplicantDashboardView extends ConsumerStatefulWidget {
  const ApplicantDashboardView({super.key});

  static const String path = NavigatorRoutes.applicantDashboard;

  @override
  ConsumerState<ApplicantDashboardView> createState() =>
      _ApplicantDashboardViewState();
}

class _ApplicantDashboardViewState
    extends ConsumerState<ApplicantDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(applicantDashboardViewModelProvider)
            .bootstrapDashboardSilently(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(applicantDashboardViewModelProvider);
    final title = vm.appBarTitle(vm.data);
    final headerBg = vm.applicantDashboardHeaderBackgroundAsset(vm.data);

    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(headerBg),
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: DthAppBar(
          title: title,
          onBack: () => vm.handleBack(context),
          backgroundColor: Colors.transparent,
        ),
        body: vm.baseState.when(
          busy: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (Failure failure) => Center(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              children: [
                AppText.semiBold(
                  "Could not load dashboard",
                  fontSize: 16,
                  color: AppColors.mainBlack,
                  textAlign: TextAlign.center,
                ),
                Gap.h12,
                AppText.regular(
                  failure.message,
                  fontSize: 14,
                  color: AppColors.blackTint20,
                  textAlign: TextAlign.center,
                ),
                Gap.h24,
                Center(
                  child: AppButton.primary(
                    text: "Retry",
                    height: 48,
                    press: () => unawaited(vm.bootstrapDashboardSilently()),
                  ),
                ),
              ],
            ),
          ),
          idle: () {
            final data = vm.data;
            if (data != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ApplicantDashboardScrollBody(data: data, viewModel: vm),
              );
            }
            return const SizedBox.expand();
          },
        ),
      ),
    );
  }
}
