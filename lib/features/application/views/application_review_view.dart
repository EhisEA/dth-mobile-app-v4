import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/models/application_draft.dart';
import 'package:dth_v4/data/models/application_process_models.dart';
import 'package:dth_v4/features/application/components/review_section_card.dart';
import 'package:dth_v4/features/bottomNavBar/bottom_nav_bar.dart';
import 'package:dth_v4/features/application/view_model/application_view_model.dart';
import 'package:dth_v4/widgets/text/textstyles.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class ApplicationReviewView extends ConsumerStatefulWidget {
  const ApplicationReviewView({super.key, this.routeDraft});

  /// When non-null (from route [RoutingArgumentKey.applicationDraft]), hydrates [ApplicationViewModel] so the UI matches the passed model.
  final ApplicationDraft? routeDraft;

  static const String path = NavigatorRoutes.applicationReview;

  static String maskAccountNumber(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    const keepStart = 2;
    const keepEnd = 4;
    if (d.length < keepStart + keepEnd) return d;
    final mid = d.length - keepStart - keepEnd;
    return '${d.substring(0, keepStart)}${'x' * mid}${d.substring(d.length - keepEnd)}';
  }

  static List<ReviewSectionField> _personalRows(ApplicationDraft d) {
    return [
      (label: 'Full Name', value: d.fullName, forceFullWidth: false),
      (label: 'Email Address', value: d.email, forceFullWidth: false),
      (
        label: 'Date of Birth',
        value: d.dateOfBirthDisplay,
        forceFullWidth: false,
      ),
      (label: 'Gender', value: d.gender, forceFullWidth: false),
      (label: 'Phone Number', value: d.phoneNumber, forceFullWidth: false),
    ];
  }

  static List<ReviewSectionField> _contactRows(
    ApplicationDraft d,
    ApplicationProcess? process,
  ) {
    final nearestCampusLabel =
        process?.nearestCampusDisplay(d.nearestCampus) ?? d.nearestCampus;
    return [
      (
        label: 'Residential Address',
        value: d.residentialAddress,
        forceFullWidth: false,
      ),
      (
        label: 'State of Residence',
        value: d.stateOfResidence,
        forceFullWidth: false,
      ),
      (label: 'City/Town', value: d.cityOfResidence, forceFullWidth: false),
      (label: 'State of Origin', value: d.stateOfOrigin, forceFullWidth: false),
      (label: 'LGA', value: d.lga, forceFullWidth: false),
      (
        label: 'Nearest Campus',
        value: nearestCampusLabel,
        forceFullWidth: false,
      ),
    ];
  }

  static List<ReviewSectionField> _talentRows(ApplicationDraft d) {
    final rows = <ReviewSectionField>[
      (label: 'Stage Name', value: d.stageName, forceFullWidth: false),
      (
        label: 'Talent Category',
        value: d.talentCategory,
        forceFullWidth: false,
      ),
      (label: 'Description', value: d.talentDescription, forceFullWidth: false),
      (label: 'Mode', value: d.presentationMode, forceFullWidth: false),
    ];
    if (d.isGroupPresentation) {
      rows.add((label: 'Size', value: d.crewSize, forceFullWidth: false));
      rows.add((
        label: 'Name of Participants',
        value: d.participantNames,
        forceFullWidth: false,
      ));
    }
    return rows;
  }

  static List<ReviewSectionField> _videoRows(ApplicationDraft d) {
    return [
      (label: 'Video Link', value: d.videoLink, forceFullWidth: true),
      (label: 'Social Media', value: d.socialMediaLink, forceFullWidth: true),
    ];
  }

  static List<ReviewSectionField> _bankRows(ApplicationDraft d) {
    return [
      (label: 'Bank Name', value: d.bankName, forceFullWidth: false),
      (
        label: 'Account Number',
        value: maskAccountNumber(d.accountNumber),
        forceFullWidth: false,
      ),
      (label: 'Account Name', value: d.accountName, forceFullWidth: false),
    ];
  }

  @override
  ConsumerState<ApplicationReviewView> createState() =>
      _ApplicationReviewViewState();
}

class _ApplicationReviewViewState extends ConsumerState<ApplicationReviewView> {
  @override
  void initState() {
    super.initState();
    final d = widget.routeDraft;
    if (d != null) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(applicationViewModelProvider).replaceDraft(d);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // final draft = ref.watch(
    //   applicationViewModelProvider.select((vm) => vm.draft),
    // );
    final vm = ref.watch(applicationViewModelProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.greyTint15),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SvgPicture.asset(
                            SvgAssets.backArrow,
                            height: 20,
                            width: 20,
                            colorFilter: const ColorFilter.mode(
                              AppColors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Gap.w24,
                    const Expanded(child: SizedBox.shrink()),
                    GestureDetector(
                      onTap: () => HapticFeedback.lightImpact(),
                      child: SvgPicture.asset(SvgAssets.support),
                    ),
                  ],
                ),
                Gap.h18,
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      AppText.medium(
                        'Review Submission',
                        fontSize: 24,
                        letterSpacing: -0.4,
                        color: AppColors.tertiary60,
                      ),
                      Gap.h8,
                      AppText.regular(
                        "Kindly review your application carefully as edits won't be possible after submission.",
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.blackTint20,
                      ),
                      Gap.h24,
                      ReviewSectionCard(
                        title: 'Personal Information',
                        wizardPageIndex: 0,
                        rows: ApplicationReviewView._personalRows(vm.draft),
                      ),
                      Gap.h12,
                      ReviewSectionCard(
                        title: 'Contact Information',
                        wizardPageIndex: 1,
                        rows: ApplicationReviewView._contactRows(
                          vm.draft,
                          vm.applicationProcess,
                        ),
                      ),
                      Gap.h12,
                      ReviewSectionCard(
                        title: 'Talent Showcase',
                        wizardPageIndex: 2,
                        rows: ApplicationReviewView._talentRows(vm.draft),
                      ),
                      Gap.h12,
                      ReviewSectionCard(
                        title: 'Audition Video',
                        wizardPageIndex: 3,
                        rows: ApplicationReviewView._videoRows(vm.draft),
                      ),
                      if (vm.applicationProcess?.collectBankDetails ??
                          false) ...[
                        Gap.h12,
                        ReviewSectionCard(
                          title: 'Bank Details',
                          wizardPageIndex: 4,
                          rows: ApplicationReviewView._bankRows(vm.draft),
                        ),
                      ],
                      Gap.h24,
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: AppButton.primary(
                    text: 'Submit',
                    isLoading: vm.submitApplicationState.isBusy,
                    press: () async {
                      FocusScope.of(context).unfocus();
                      final body = vm.requestFromDraft(
                        vm.draft,
                        isFinalStep: true,
                      );

                      await vm.submitApplication(
                        body: body,
                        onSuccess: () {
                          ref.read(applicationViewModelProvider).reset();
                          MobileNavigationService.instance.popUntil(
                            BottomNavBar.path,
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Proudly sponsored by ',
                          style: AppTextStyle.regular.copyWith(
                            fontSize: 12,
                            color: AppColors.blackTint20,
                          ),
                        ),
                        TextSpan(
                          text: 'Vent Africa',
                          style: AppTextStyle.regular.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff009DF9),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
