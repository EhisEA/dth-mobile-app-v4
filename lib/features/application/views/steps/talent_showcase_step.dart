import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/application_process_models.dart";
import "package:dth_v4/data/models/application_wizard_inputs.dart";
import "package:dth_v4/features/application/view_model/application_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

const _kCrewSizeOptions = <String>[
  "2 Persons",
  "3 Persons",
  "4 Persons",
  "5 Persons",
  "6+ Persons",
];

class TalentShowcaseStep extends ConsumerStatefulWidget {
  const TalentShowcaseStep({
    super.key,
    required this.formKey,
    required this.onRegisterPersist,
    required this.applicationProcess,
  });

  final GlobalKey<FormState> formKey;
  final void Function(void Function() persist) onRegisterPersist;
  final ApplicationProcess applicationProcess;

  @override
  ConsumerState<TalentShowcaseStep> createState() => _TalentShowcaseStepState();
}

class _TalentShowcaseStepState extends ConsumerState<TalentShowcaseStep>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final FocusNode _stageFocus;
  late final FocusNode _descriptionFocus;
  late final FocusNode _participantsFocus;
  late final TextEditingController _stageController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _participantsController;

  String? _category;
  String? _presentationMode;
  String? _crewSize;

  bool get _isGroup =>
      (_presentationMode ?? "").toLowerCase() == "group";

  @override
  void initState() {
    super.initState();
    _stageFocus = FocusNode();
    _descriptionFocus = FocusNode();
    _participantsFocus = FocusNode();
    _stageController = TextEditingController();
    _descriptionController = TextEditingController();
    _participantsController = TextEditingController();
    widget.onRegisterPersist(_persist);
  }

  @override
  void dispose() {
    _stageFocus.dispose();
    _descriptionFocus.dispose();
    _participantsFocus.dispose();
    _stageController.dispose();
    _descriptionController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  void _persist() {
    final mode = _presentationMode ?? '';
    ref
        .read(applicationViewModelProvider)
        .setTalentShowcase(
          TalentShowcaseInput(
            stageName: _stageController.text.trim(),
            talentCategory: _category ?? '',
            talentDescription: _descriptionController.text.trim(),
            presentationMode: mode,
            crewSize: _isGroup ? (_crewSize ?? '') : '',
            participantNames:
                _isGroup ? _participantsController.text.trim() : '',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final categoryOptions = [
      for (final category in widget.applicationProcess.talentCategories)
        AppDropdownOption(value: category.name, label: category.name),
    ];
    final modeOptions = [
      for (final mode in widget.applicationProcess.presentationModes)
        AppDropdownOption(value: mode.value, label: mode.label),
    ];
    final crewOptions = [
      for (final size in _kCrewSizeOptions)
        AppDropdownOption(value: size, label: size),
    ];

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          AppText.medium(
            'Talent Showcase',
            fontSize: 24,
            letterSpacing: -0.4,
            color: AppColors.tertiary60,
          ),
          Gap.h8,
          AppText.regular(
            'Share details about your talent and whether you perform individually or as a group.',
            fontSize: 14,
            height: 1.4,
            color: AppColors.blackTint20,
          ),
          Gap.h24,
          AppTextField(
            title: 'Stage Name',
            hint: 'Enter your stage name',
            controller: _stageController,
            focusNode: _stageFocus,
            titleColor: AppColors.black,
            validator: (v) =>
                v.trim().isEmpty ? 'This field is required' : null,
            textInputAction: TextInputAction.next,
            formatter: [FilteringTextInputFormatter.singleLineFormatter],
          ),
          Gap.h16,
          AppDropdownFormField<String>(
            title: 'Talent Category',
            hint: 'Select category',
            options: categoryOptions,
            onChanged: (v) => setState(() => _category = v),
          ),
          Gap.h16,
          AppTextField(
            title: 'Description',
            hint: 'Briefly tell us more about your talent',
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            titleColor: AppColors.black,
            validator: (v) =>
                v.trim().isEmpty ? 'This field is required' : null,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.next,
          ),
          Gap.h16,
          AppDropdownFormField<String>(
            title: 'Mode of Presentation',
            hint: 'Group or Individual',
            options: modeOptions,
            onChanged: (v) {
              setState(() {
                _presentationMode = v;
                if (!_isGroup) {
                  _crewSize = null;
                  _participantsController.clear();
                }
              });
            },
          ),
          if (_isGroup) ...[
            Gap.h16,
            AppDropdownFormField<String>(
              key: const ValueKey('crew_size'),
              title: 'Size of Crew',
              hint: 'Enter size of crew?',
              options: crewOptions,
              onChanged: (v) => setState(() => _crewSize = v),
              validator: (v) {
                if (!_isGroup) return null;
                if (v == null || v.isEmpty) return 'This field is required';
                return null;
              },
            ),
            Gap.h16,
            AppTextField(
              title: 'Name of Participants',
              hint: 'Enter the full name of your crew members',
              controller: _participantsController,
              focusNode: _participantsFocus,
              titleColor: AppColors.black,
              validator: Validator.emptyField,
              maxLines: 4,
              minLines: 2,
              textInputAction: TextInputAction.done,
            ),
          ],
          Gap.h32,
        ],
      ),
    );
  }
}
