import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/applicant_dashboard_models.dart";
import "package:dth_v4/features/application/components/application_segmented_progress.dart";
import "package:dth_v4/features/application_dashboard/view_model/applicant_dashboard_view_model.dart";
import "package:dth_v4/features/support/view_model/support_session_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Renders a server-driven [InfoForm] as a multi-step wizard. Each
/// [InfoFormStep] becomes a page; fields are built from their [InfoFormFieldType].
/// A trailing read-only preview submits the answers (keyed by
/// [InfoFormField.key]) via [ApplicantDashboardViewModel.submitInfoForm].
class InfoFormBuilderView extends ConsumerStatefulWidget {
  const InfoFormBuilderView({super.key, required this.form});
  static const String path = NavigatorRoutes.infoFormBuilder;

  final InfoForm form;

  @override
  ConsumerState<InfoFormBuilderView> createState() =>
      _InfoFormBuilderViewState();
}

class _InfoFormBuilderViewState extends ConsumerState<InfoFormBuilderView> {
  late final List<InfoFormStep> _steps = widget.form.steps;
  late final int _stepCount = _steps.length;

  late final List<GlobalKey<FormState>> _formKeys = List.generate(
    _stepCount,
    (_) => GlobalKey<FormState>(),
    growable: false,
  );

  late final PageController _pageController;

  /// Text-like field controllers/focus, keyed by [InfoFormField.key].
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  /// Current value of each `select` field, keyed by [InfoFormField.key].
  final Map<String, String?> _selectValues = {};

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    for (final field in widget.form.allFields) {
      if (field.type == InfoFormFieldType.select) {
        _selectValues[field.key] = null;
      } else {
        _controllers[field.key] = TextEditingController();
        _focusNodes[field.key] = FocusNode();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
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

  /// The trailing read-only preview page (index == [_stepCount]).
  bool get _isReviewPage => _currentIndex == _stepCount;

  Future<void> _onProceed() async {
    FocusScope.of(context).unfocus();

    // The preview is the last page; its button submits.
    if (_isReviewPage) {
      _submit();
      return;
    }

    final formState = _formKeys[_currentIndex].currentState;
    if (formState == null || !formState.validate()) return;

    // Persist the draft before advancing; stay on this step if the save fails.
    final saved = await ref
        .read(applicantDashboardViewModelProvider)
        .saveInfoFormFields(_collectValues());
    if (!saved || !mounted) return;

    // Advancing past the final form step lands on the preview page.
    await _pageController.animateToPage(
      _currentIndex + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToStep(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Snapshot of all answers keyed by [InfoFormField.key] (empty values dropped).
  /// `number` fields are sent as ints to match the API contract.
  Map<String, dynamic> _collectValues() {
    final values = <String, dynamic>{};
    for (final field in widget.form.allFields) {
      if (field.type == InfoFormFieldType.select) {
        final v = _selectValues[field.key];
        if (v != null && v.isNotEmpty) values[field.key] = v;
      } else {
        final text = _controllers[field.key]?.text.trim() ?? "";
        if (text.isEmpty) continue;
        if (field.type == InfoFormFieldType.number) {
          values[field.key] = int.tryParse(text) ?? text;
        } else {
          values[field.key] = text;
        }
      }
    }
    return values;
  }

  Future<void> _submit() async {
    final values = _collectValues();
    final ok = await ref
        .read(applicantDashboardViewModelProvider)
        .submitInfoForm(values);
    if (!ok || !mounted) return;
    DthFlushBar.instance.showSuccess(
      title: "Success",
      message: "Your details have been submitted.",
    );
    Navigator.of(context).pop(true);
  }

  String _primaryButtonLabel() {
    if (_isReviewPage) return "Submit";
    final label = _steps[_currentIndex].submit.label.trim();
    // The final form step leads into the preview, not a direct submit.
    if (_currentIndex == _stepCount - 1) return "Proceed";
    return label.isNotEmpty ? label : "Proceed";
  }

  @override
  Widget build(BuildContext context) {
    if (_stepCount == 0) {
      return _emptyScaffold(context);
    }
    // Loader for the primary button: saving a step draft, or final submit.
    final actionBusy = ref.watch(
      applicantDashboardViewModelProvider.select(
        (m) =>
            m.submitInfoFormState.isBusy || m.saveInfoFormFieldsState.isBusy,
      ),
    );
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Gap.h8,
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemCount: _stepCount + 1,
                  itemBuilder: (context, i) => i < _stepCount
                      ? _buildStep(_steps[i], i)
                      : _buildReviewPage(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AppButton.primary(
                  text: _primaryButtonLabel(),
                  isLoading: actionBusy,
                  press: _onProceed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _circleBackButton(onTap: _onBack),
          Gap.w24,
          Expanded(
            child: _isReviewPage
                ? const SizedBox.shrink()
                : ApplicationSegmentedProgress(
                    currentStepIndex: _currentIndex,
                    totalSteps: _stepCount,
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
    );
  }

  Widget _buildStep(InfoFormStep step, int index) {
    final pageTitle = step.page.title?.trim() ?? "";
    final pageDescription = step.page.description?.trim() ?? "";

    return Form(
      key: _formKeys[index],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (pageTitle.isNotEmpty)
            AppText.medium(
              pageTitle,
              fontSize: 24,
              letterSpacing: -0.4,
              color: AppColors.tertiary60,
            ),
          if (pageDescription.isNotEmpty) ...[
            Gap.h8,
            AppText.regular(
              pageDescription,
              fontSize: 14,
              height: 1.4,
              color: AppColors.blackTint20,
            ),
          ],
          Gap.h24,
          for (final section in step.sections)
            ..._buildSection(section, pageTitle),
          Gap.h32,
        ],
      ),
    );
  }

  List<Widget> _buildSection(InfoFormSection section, String pageTitle) {
    final widgets = <Widget>[];
    final sectionTitle = section.title?.trim() ?? "";
    final sectionSubtitle = section.subtitle?.trim() ?? "";

    // Skip a section title that merely repeats the page title.
    if (sectionTitle.isNotEmpty &&
        sectionTitle.toLowerCase() != pageTitle.toLowerCase()) {
      widgets.add(Gap.h8);
      widgets.add(
        AppText.medium(
          sectionTitle,
          fontSize: 14,
          color: AppColors.black,
          fontWeight: FontWeight.w500,
        ),
      );
      widgets.add(Gap.h4);
    }
    if (sectionSubtitle.isNotEmpty) {
      widgets.add(
        AppText.regular(
          sectionSubtitle,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.tint25,
        ),
      );
      widgets.add(Gap.h16);
    }

    for (var i = 0; i < section.rows.length; i++) {
      widgets.add(_buildRow(section.rows[i]));
      if (i < section.rows.length - 1) widgets.add(Gap.h16);
    }
    return widgets;
  }

  Widget _buildRow(List<InfoFormField> row) {
    if (row.length == 1) return _buildField(row.first);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < row.length; i++) ...[
          if (i > 0) Gap.w12,
          Expanded(child: _buildField(row[i])),
        ],
      ],
    );
  }

  Widget _buildField(InfoFormField field) {
    final caption = _captionFor(field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AppText.medium(
        //   field.required ? "${field.label} *" : field.label,
        //   fontSize: 14,
        //   height: 1.35,
        //   color: AppColors.black,
        // ),
        if (caption != null) ...[
          Gap.h4,
          AppText.regular(
            caption,
            fontSize: 12,
            height: 1.35,
            color: AppColors.blackTint20,
          ),
        ],
        Gap.h8,
        _buildInput(field),
      ],
    );
  }

  /// Helper text below the label; for selects the placeholder often carries
  /// conditional guidance ("If yes, mention…") so surface it here too.
  String? _captionFor(InfoFormField field) {
    final help = field.helpText?.trim();
    if (help != null && help.isNotEmpty) return help;
    if (field.type == InfoFormFieldType.select) {
      final ph = field.placeholder?.trim();
      if (ph != null && ph.isNotEmpty) return ph;
    }
    return null;
  }

  Widget _buildInput(InfoFormField field) {
    switch (field.type) {
      case InfoFormFieldType.select:
        return AppDropdownFormField<String>(
          title: field.required ? "${field.label} *" : field.label,
          titleSize: 12,
          hint: "Select an option",
          options: [
            for (final o in field.options)
              AppDropdownOption(value: o, label: o),
          ],
          initialValue: _selectValues[field.key],
          validator: field.required ? null : (_) => null,
          onChanged: (v) => setState(() => _selectValues[field.key] = v),
        );
      case InfoFormFieldType.textarea:
        return AppTextField(
          hint: field.placeholder ?? "",
          title: field.required ? "${field.label} *" : field.label,
          titleSize: 12,
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          minLines: 3,
          titleColor: AppColors.greyTint55,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          validator: field.required ? (v) => Validator.emptyField(v) : null,
        );
      case InfoFormFieldType.number:
        return AppTextField(
          hint: field.placeholder ?? "",
          title: field.required ? "${field.label} *" : field.label,
          titleSize: 12,
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          formatter: [FilteringTextInputFormatter.digitsOnly],
          validator: field.required ? (v) => Validator.emptyField(v) : null,
        );
      case InfoFormFieldType.text:
      case InfoFormFieldType.unknown:
        return AppTextField(
          hint: field.placeholder ?? "",
          title: field.required ? "${field.label} *" : field.label,
          titleSize: 12,
          controller: _controllers[field.key],
          focusNode: _focusNodes[field.key],
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          formatter: [FilteringTextInputFormatter.singleLineFormatter],
          validator: field.required ? (v) => Validator.emptyField(v) : null,
        );
    }
  }

  // --- Preview / review page ---------------------------------------------

  Widget _buildReviewPage() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        AppText.medium(
          "Review Submission",
          fontSize: 24,
          letterSpacing: -0.4,
          color: AppColors.tertiary60,
        ),
        Gap.h8,
        AppText.regular(
          "Kindly review your details carefully before submitting.",
          fontSize: 14,
          height: 1.4,
          color: AppColors.blackTint20,
        ),
        Gap.h24,
        for (var i = 0; i < _stepCount; i++) ...[
          _reviewCard(_steps[i], i),
          Gap.h12,
        ],
        Gap.h32,
      ],
    );
  }

  Widget _reviewCard(InfoFormStep step, int stepIndex) {
    final fields = step.fields;
    final title = step.page.title?.trim() ?? "";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText.medium(
                  title.isEmpty ? "Step ${stepIndex + 1}" : title,
                  fontSize: 14,
                  color: AppColors.tertiary60,
                ),
              ),
              GestureDetector(
                onTap: () => _goToStep(stepIndex),
                behavior: HitTestBehavior.opaque,
                child: SvgPicture.asset(SvgAssets.edit),
              ),
            ],
          ),
          Gap.h12,
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) Gap.h16,
            _reviewFieldCell(fields[i]),
          ],
        ],
      ),
    );
  }

  Widget _reviewFieldCell(InfoFormField field) {
    final value = _displayValueFor(field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.regular(
          field.label,
          fontSize: 10,
          height: 1.3,
          color: AppColors.tint15,
          maxLines: 3,
        ),
        Gap.h4,
        AppText.regular(
          value.isEmpty ? "—" : value,
          fontSize: 12,
          height: 1.35,
          color: AppColors.black,
        ),
      ],
    );
  }

  String _displayValueFor(InfoFormField field) {
    if (field.type == InfoFormFieldType.select) {
      return _selectValues[field.key] ?? "";
    }
    return _controllers[field.key]?.text.trim() ?? "";
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

  Widget _emptyScaffold(BuildContext context) {
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
            Expanded(
              child: Center(
                child: AppText.regular(
                  "Nothing to fill in",
                  fontSize: 14,
                  color: AppColors.blackTint20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
