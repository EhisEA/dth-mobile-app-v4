import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/models/application_process_models.dart';
import 'package:dth_v4/features/application/view_model/application_view_model.dart';
import 'package:dth_v4/features/application/views/application_review_view.dart';
import 'package:dth_v4/features/application/views/steps/audition_video_step.dart';
import 'package:dth_v4/features/application/views/steps/bank_details_step.dart';
import 'package:dth_v4/features/application/views/steps/contact_information_step.dart';
import 'package:dth_v4/features/application/views/steps/personal_information_step.dart';
import 'package:dth_v4/features/application/views/steps/talent_showcase_step.dart';
import 'package:dth_v4/features/application/components/application_segmented_progress.dart';
import 'package:dth_v4/features/support/support.dart';
import 'package:dth_v4/widgets/text/textstyles.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_utils/flutter_utils.dart';

class ApplicationView extends ConsumerStatefulWidget {
  const ApplicationView({super.key});
  static const String path = NavigatorRoutes.application;

  @override
  ConsumerState<ApplicationView> createState() => _ApplicationViewState();
}

class _ApplicationViewState extends ConsumerState<ApplicationView> {
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    5,
    (_) => GlobalKey<FormState>(),
  );
  final List<void Function()?> _persistFns = List.filled(5, null);

  late final PageController _pageController;

  int _currentIndex = 0;

  static int _stepCount(ApplicationProcess p) => p.collectBankDetails ? 5 : 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplicationProcess();
    });
  }

  Future<void> _loadApplicationProcess() async {
    await ref.read(applicationViewModelProvider).fetchApplicationProcess();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _registerPersist(int step, void Function() fn) {
    _persistFns[step] = fn;
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    if (_currentIndex == 0) {
      Navigator.of(context).pop();
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _circleBackButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }

  String _primaryButtonLabel() {
    return 'Proceed';
  }

  String _primaryButtonSubtitle(ApplicationProcess process) {
    switch (_currentIndex) {
      case 0:
        return '(Contact Information)';
      case 1:
        return '(Talent Showcase)';
      case 2:
        return '(Audition Video)';
      case 3:
        return process.collectBankDetails ? '(Bank Details)' : '(Review)';
      case 4:
        return '(Review)';
      default:
        return '';
    }
  }

  Widget _buildProcessLoadingScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _circleBackButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessErrorScaffold(BuildContext context, Failure failure) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    _circleBackButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppText.medium(
                'Could not load application',
                fontSize: 20,
                color: AppColors.tertiary60,
              ),
              Gap.h12,
              AppText.regular(
                failure.message,
                fontSize: 14,
                height: 1.4,
                color: AppColors.blackTint20,
                textAlign: TextAlign.center,
              ),
              Gap.h24,
              AppButton.primary(text: 'Retry', press: _loadApplicationProcess),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizardScaffold(
    BuildContext context,
    ApplicationProcess process,
  ) {
    final vm = ref.watch(supportSessionViewModelProvider);
    return Loader.page(
      isLoading: vm.supportSessionBusy,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _onBack,
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
                    Expanded(
                      child: ApplicationSegmentedProgress(
                        currentStepIndex: _currentIndex,
                        totalSteps: _stepCount(process),
                      ),
                    ),
                    Gap.w24,
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await ref
                            .read(supportSessionViewModelProvider)
                            .requestSupportWebSession();
                      },
                      child: SvgPicture.asset(SvgAssets.support),
                    ),
                  ],
                ),
              ),
              Gap.h8,
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  children: [
                    PersonalInformationStep(
                      formKey: _formKeys[0],
                      onRegisterPersist: (fn) => _registerPersist(0, fn),
                      applicationProcess: process,
                    ),
                    ContactInformationStep(
                      formKey: _formKeys[1],
                      onRegisterPersist: (fn) => _registerPersist(1, fn),
                      applicationProcess: process,
                    ),
                    TalentShowcaseStep(
                      formKey: _formKeys[2],
                      onRegisterPersist: (fn) => _registerPersist(2, fn),
                      applicationProcess: process,
                    ),
                    AuditionVideoStep(
                      formKey: _formKeys[3],
                      onRegisterPersist: (fn) => _registerPersist(3, fn),
                    ),
                    if (process.collectBankDetails)
                      BankDetailsStep(
                        formKey: _formKeys[4],
                        onRegisterPersist: (fn) => _registerPersist(4, fn),
                        applicationProcess: process,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AppButton.primary(
                  text: _primaryButtonLabel(),
                  press: () => _onProceed(process),
                  subtitle: _primaryButtonSubtitle(process),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyle.regular.copyWith(
                      fontSize: 11,
                      color: AppColors.blackTint20,
                    ),
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
    );
  }

  Future<void> _onProceed(ApplicationProcess process) async {
    FocusScope.of(context).unfocus();
    final steps = _stepCount(process);
    final form = _formKeys[_currentIndex].currentState;
    if (form == null || !form.validate()) return;
    _persistFns[_currentIndex]?.call();

    if (_currentIndex < steps - 1) {
      await _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      final draft = ref.read(applicationViewModelProvider).draft;
      final result = await MobileNavigationService.instance.navigateTo(
        ApplicationReviewView.path,
        extra: {RoutingArgumentKey.applicationDraft: draft},
      );
      if (!mounted) return;
      if (result == null) return;
      if (result is int && result >= 0 && result < steps) {
        _pageController.jumpToPage(result);
        setState(() => _currentIndex = result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(applicationViewModelProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: model.baseState.when(
        idle: () {
          final process = model.applicationProcess;
          if (process == null) {
            return const SizedBox.shrink();
          }
          return _buildWizardScaffold(context, process);
        },
        error: (Failure failure) =>
            _buildProcessErrorScaffold(context, failure),
        busy: () => _buildProcessLoadingScaffold(context),
      ),
    );
  }
}
