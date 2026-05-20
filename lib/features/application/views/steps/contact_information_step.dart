import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/application_process_models.dart";
import "package:dth_v4/data/models/application_wizard_inputs.dart";
import "package:dth_v4/features/application/view_model/application_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class ContactInformationStep extends ConsumerStatefulWidget {
  const ContactInformationStep({
    super.key,
    required this.formKey,
    required this.onRegisterPersist,
    required this.applicationProcess,
  });

  final GlobalKey<FormState> formKey;
  final void Function(void Function() persist) onRegisterPersist;
  final ApplicationProcess applicationProcess;

  @override
  ConsumerState<ContactInformationStep> createState() =>
      _ContactInformationStepState();
}

class _ContactInformationStepState extends ConsumerState<ContactInformationStep>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final FocusNode _addressFocus;
  late final FocusNode _cityFocus;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;

  /// When [ApplicationProcess.nearestCampuses] is empty, free text is still allowed.
  FocusNode? _nearestCampusFreeTextFocus;
  TextEditingController? _nearestCampusFreeTextController;

  /// Selected API `value` when campus options exist.
  String? _nearestCampusValue;

  String? _stateOfResidence;
  String? _stateOfOrigin;
  String? _lga;

  String? _lgaPrerequisiteError;

  List<ApplicationLabelValue> get _campuses =>
      widget.applicationProcess.nearestCampuses;

  void _hydrateNearestCampusFromDraft(String raw) {
    final saved = raw.trim();
    if (saved.isEmpty) return;
    if (_campuses.isEmpty) {
      _nearestCampusFreeTextController?.text = saved;
      return;
    }
    for (final c in _campuses) {
      if (c.value == saved) {
        _nearestCampusValue = saved;
        return;
      }
    }
    for (final c in _campuses) {
      if (c.label == saved) {
        _nearestCampusValue = c.value;
        return;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _addressFocus = FocusNode();
    _cityFocus = FocusNode();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    if (_campuses.isEmpty) {
      _nearestCampusFreeTextFocus = FocusNode();
      _nearestCampusFreeTextController = TextEditingController();
    }
    final draft = ref.read(applicationViewModelProvider).draft;
    if (draft.cityOfResidence.trim().isNotEmpty) {
      _cityController.text = draft.cityOfResidence.trim();
    }
    _hydrateNearestCampusFromDraft(draft.nearestCampus);
    widget.onRegisterPersist(_persist);
  }

  @override
  void dispose() {
    _addressFocus.dispose();
    _cityFocus.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _nearestCampusFreeTextFocus?.dispose();
    _nearestCampusFreeTextController?.dispose();
    super.dispose();
  }

  void _persist() {
    final nearestCampus = _campuses.isEmpty
        ? (_nearestCampusFreeTextController?.text.trim() ?? '')
        : (_nearestCampusValue ?? '');
    ref
        .read(applicationViewModelProvider)
        .setContact(
          ContactInformationInput(
            residentialAddress: _addressController.text.trim(),
            stateOfResidence: _stateOfResidence ?? '',
            cityOfResidence: _cityController.text.trim(),
            stateOfOrigin: _stateOfOrigin ?? '',
            lga: _lga ?? '',
            nearestCampus: nearestCampus,
          ),
        );
  }

  /// All states we got from the server (one menu item per state).
  List<AppDropdownOption<String>> _stateOptions() {
    return [
      for (final location in widget.applicationProcess.locations)
        AppDropdownOption(value: location.state, label: location.state),
    ];
  }

  /// LGAs for their state of origin. No items until they pick state of origin.
  List<AppDropdownOption<String>> _lgaOptions() {
    if (_stateOfOrigin == null) return [];
    final location = widget.applicationProcess.locationForState(
      _stateOfOrigin!,
    );
    if (location == null) return [];
    return [
      for (final lga in location.lgas)
        AppDropdownOption(value: lga, label: lga),
    ];
  }

  List<AppDropdownOption<String>> _nearestCampusOptions() {
    return [
      for (final c in _campuses)
        AppDropdownOption<String>(value: c.value, label: c.label),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lgas = _lgaOptions();
    final campusOptions = _nearestCampusOptions();

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          AppText.medium(
            'Contact Information',
            fontSize: 24,
            letterSpacing: -0.4,
            color: AppColors.tertiary60,
          ),
          Gap.h8,
          AppText.regular(
            'Provide your contact details so we can reach you with important updates.',
            fontSize: 14,
            height: 1.4,
            color: AppColors.blackTint20,
          ),
          Gap.h24,
          AppTextField(
            title: 'Residential Address',
            hint: 'Enter your address',
            controller: _addressController,
            titleColor: AppColors.black,
            focusNode: _addressFocus,
            validator: Validator.emptyField,
            textInputAction: TextInputAction.next,
            maxLines: 3,
            minLines: 1,
          ),
          Gap.h16,
          AppDropdownFormField<String>(
            title: 'State of Residence',
            hint: 'Select state of residence',
            search: true,
            options: _stateOptions(),
            onChanged: (v) {
              setState(() {
                _stateOfResidence = v;
                _cityController.clear();
              });
            },
          ),
          Gap.h16,
          AppTextField(
            title: 'City/Town',
            hint: 'Enter your city or town',
            controller: _cityController,
            titleColor: AppColors.black,
            focusNode: _cityFocus,
            validator: Validator.emptyField,
            textInputAction: TextInputAction.next,
          ),
          Gap.h16,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDropdownFormField<String>(
                  title: 'State of Origin',
                  hint: 'Select state',
                  search: true,
                  options: _stateOptions(),
                  onChanged: (v) {
                    setState(() {
                      _stateOfOrigin = v;
                      _lga = null;
                      _lgaPrerequisiteError = null;
                    });
                  },
                ),
              ),
              Gap.w12,
              Expanded(
                child: AppDropdownFormField<String>(
                  key: ValueKey<String?>('lga_${_stateOfOrigin ?? 'none'}'),
                  title: 'LGA',
                  hint: _stateOfOrigin == null
                      ? 'Select state first'
                      : 'Select LGA',
                  search: true,
                  options: lgas,
                  enabled: _stateOfOrigin != null && lgas.isNotEmpty,
                  interactionError: _lgaPrerequisiteError,
                  onDisabledTap: () {
                    setState(() {
                      if (_stateOfOrigin == null) {
                        _lgaPrerequisiteError =
                            "Select your state of origin before choosing an LGA.";
                      } else if (lgas.isEmpty) {
                        _lgaPrerequisiteError =
                            "No LGA options are available for the selected state of origin. "
                            "Choose a different state.";
                      }
                    });
                  },
                  onChanged: (v) => setState(() {
                    _lga = v;
                    _lgaPrerequisiteError = null;
                  }),
                  validator: (v) {
                    if (_stateOfOrigin == null) return null;
                    if (lgas.isEmpty) return null;
                    if (v == null || v.isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          Gap.h16,
          if (_campuses.isEmpty)
            AppTextField(
              title: 'Nearest Campus',
              hint: 'Enter the campus nearest to you',
              controller: _nearestCampusFreeTextController!,
              focusNode: _nearestCampusFreeTextFocus!,
              titleColor: AppColors.black,
              validator: Validator.emptyField,
              textInputAction: TextInputAction.done,
            )
          else
            AppDropdownFormField<String>(
              key: ValueKey<String?>(
                'nearest_campus_${campusOptions.length}_$_nearestCampusValue',
              ),
              title: 'Nearest Campus',
              hint: 'Select nearest campus',
              search: true,
              options: campusOptions,
              initialValue: _nearestCampusValue,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
              onChanged: (v) => setState(() {
                _nearestCampusValue = v;
              }),
            ),
          Gap.h32,
        ],
      ),
    );
  }
}
