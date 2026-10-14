import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/store/store.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoreShippingAddressView extends ConsumerStatefulWidget {
  const StoreShippingAddressView({super.key, this.addressUid});

  static const String path = NavigatorRoutes.storeShippingAddress;

  /// When set, Save calls PUT to update this address.
  final String? addressUid;

  @override
  ConsumerState<StoreShippingAddressView> createState() =>
      _StoreShippingAddressViewState();
}

class _StoreShippingAddressViewState
    extends ConsumerState<StoreShippingAddressView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _buildingController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalController;
  late final TextEditingController _phoneController;

  late final FocusNode _buildingFocus;
  late final FocusNode _streetFocus;
  late final FocusNode _cityFocus;
  late final FocusNode _stateFocus;
  late final FocusNode _postalFocus;
  late final FocusNode _phoneFocus;

  String? _countryName;
  String? _selectedState;
  bool _saving = false;

  static final _phonePattern = RegExp(r"^\+?[0-9 ()-]+$");

  String? get _editUid {
    final fromArgs = widget.addressUid?.trim();
    if (fromArgs != null && fromArgs.isNotEmpty) return fromArgs;
    return null;
  }

  bool get _isEditing => _editUid != null;

  @override
  void initState() {
    super.initState();
    // Prefill address fields only when editing; Add starts blank.
    final existing = _isEditing
        ? ref.read(cartViewModelProvider).shippingAddress
        : null;
    _buildingController = TextEditingController(
      text: existing?.buildingNo ?? "",
    );
    _streetController = TextEditingController(text: existing?.streetName ?? "");
    _cityController = TextEditingController(text: existing?.city ?? "");
    _stateController = TextEditingController(text: existing?.state ?? "");
    _postalController = TextEditingController(text: existing?.postalCode ?? "");
    _phoneController = TextEditingController(
      text: _initialPhoneNumber(existing?.phoneNumber),
    );
    _countryName = existing?.country;
    _selectedState = existing?.state;

    _buildingFocus = FocusNode();
    _streetFocus = FocusNode();
    _cityFocus = FocusNode();
    _stateFocus = FocusNode();
    _postalFocus = FocusNode();
    _phoneFocus = FocusNode();

    for (final c in [
      _buildingController,
      _streetController,
      _cityController,
      _stateController,
      _postalController,
      _phoneController,
    ]) {
      c.addListener(_onFormChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureCountriesLoaded());
    });
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _ensureCountriesLoaded() async {
    final async = ref.read(countriesListProvider);
    if (async.isLoading) return;

    final cached = async.valueOrNull;
    final usable =
        cached != null &&
        cached.isNotEmpty &&
        cached.every((c) => c.name.trim().isNotEmpty);
    if (usable) return;

    await ref
        .read(localCacheProvider)
        .removeFromLocalCache(CacheKeys.countries);
    ref.invalidate(countriesListProvider);
  }

  @override
  void dispose() {
    for (final c in [
      _buildingController,
      _streetController,
      _cityController,
      _stateController,
      _postalController,
      _phoneController,
    ]) {
      c.removeListener(_onFormChanged);
      c.dispose();
    }
    _buildingFocus.dispose();
    _streetFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _postalFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  DthCountry? _selectedCountry(List<DthCountry> countries) {
    final name = _countryName;
    if (name == null || name.trim().isEmpty) return null;
    return DthCountry.findByName(countries, name);
  }

  List<AppDropdownOption<String>> _countryOptions(List<DthCountry> countries) {
    return countries
        .where((c) => c.name.trim().isNotEmpty)
        .map((c) => AppDropdownOption(value: c.name, label: c.name))
        .toList(growable: false);
  }

  List<AppDropdownOption<String>> _stateOptions(DthCountry? country) {
    if (country == null || !country.hasFixedStates) return const [];
    return country.states
        .map((s) => AppDropdownOption(value: s, label: s))
        .toList(growable: false);
  }

  String _withLeadingPlus(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return "";
    if (trimmed.startsWith("+")) return trimmed;
    return "+$trimmed";
  }

  String _initialPhoneNumber(String? existingPhone) {
    final fromAddress = existingPhone?.trim() ?? "";
    if (fromAddress.isNotEmpty) return _withLeadingPlus(fromAddress);

    final userPhone =
        ref.read(userProfileStateProvider).user.value?.phoneNumber.trim() ?? "";
    return _withLeadingPlus(userPhone);
  }

  bool _hasCountryCode(String value) => value.trim().startsWith("+");

  /// Shown while typing when the number doesn't start with `+`.
  String? _phoneCountryCodeHint(String value) {
    final phone = value.trim();
    if (phone.isEmpty) return null;
    if (!_hasCountryCode(phone)) {
      return "Include your country code (e.g. +234…).";
    }
    return null;
  }

  bool _isValidPhone(String value) {
    final phone = value.trim();
    if (!_hasCountryCode(phone)) return false;
    if (phone.length < 8 || phone.length > 30) return false;
    return _phonePattern.hasMatch(phone);
  }

  String? _resolvedState(DthCountry? country) {
    if (country != null && country.hasFixedStates) {
      return _selectedState?.trim();
    }
    return _stateController.text.trim();
  }

  bool _canSave(List<DthCountry> countries) {
    if (_saving) return false;
    if (_buildingController.text.trim().isEmpty) return false;
    if (_streetController.text.trim().isEmpty) return false;
    if (_cityController.text.trim().isEmpty) return false;
    if (_postalController.text.trim().isEmpty) return false;
    if (!_isValidPhone(_phoneController.text)) return false;

    final country = _selectedCountry(countries);
    if (country == null || country.isoCode.trim().isEmpty) return false;

    final state = _resolvedState(country);
    if (state == null || state.isEmpty) return false;
    if (country.hasFixedStates && !country.states.contains(state)) {
      return false;
    }
    return true;
  }

  void _onCountryChanged(String? value) {
    setState(() {
      _countryName = value;
      _selectedState = null;
      _stateController.clear();
    });
  }

  Future<void> _pasteInto(TextEditingController controller) async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? "";
    if (text.isEmpty) return;
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
    setState(() {});
  }

  Widget _pasteSuffix(TextEditingController controller) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pasteInto(controller),
      child: AppText.medium("PASTE", fontSize: 12, color: AppColors.black),
    );
  }

  Future<void> _onSave(List<DthCountry> countries) async {
    if (!_canSave(countries)) return;
    HapticFeedback.lightImpact();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final country = _selectedCountry(countries);
    if (country == null) return;
    final state = _resolvedState(country);
    if (state == null || state.isEmpty) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(storeRepositoryProvider);
      final editUid = _editUid;
      final StoreCheckoutAddress saved;
      if (editUid != null) {
        saved = await repo.updateAddress(
          editUid,
          buildingNumber: _buildingController.text.trim(),
          street: _streetController.text.trim(),
          countryIso: country.isoCode,
          state: state,
          city: _cityController.text.trim(),
          postalCode: _postalController.text.trim(),
          phone: _phoneController.text.trim(),
          isDefault: true,
        );
      } else {
        saved = await repo.addAddress(
          buildingNumber: _buildingController.text.trim(),
          street: _streetController.text.trim(),
          countryIso: country.isoCode,
          state: state,
          city: _cityController.text.trim(),
          postalCode: _postalController.text.trim(),
          phone: _phoneController.text.trim(),
          isDefault: true,
        );
      }

      if (!mounted) return;
      ref
          .read(cartViewModelProvider)
          .setShippingAddress(saved.toShippingAddress());
      unawaited(ref.read(storeAddressesStateProvider).refreshQuiet());
      DthFlushBar.instance.showSuccess(
        title: "Address",
        message: editUid != null ? "Address updated." : "Address saved.",
      );
      Navigator.of(context).pop();
    } on ApiFailure catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(title: "Address", message: e.message);
    } catch (e) {
      if (!mounted) return;
      DthFlushBar.instance.showError(
        title: "Address",
        message: "Could not save address. Please try again.",
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? "Update Address" : "Add Address";
    final countriesAsync = ref.watch(countriesListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: DthAppBar(title: title),
      body: SafeArea(
        child: countriesAsync.when(
          loading: () => const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.medium(
                    "Couldn't load countries",
                    fontSize: 16,
                    color: AppColors.mainBlack,
                  ),
                  Gap.h8,
                  AppText.regular(
                    error.toString(),
                    fontSize: 13,
                    color: AppColors.tint15,
                    textAlign: TextAlign.center,
                  ),
                  Gap.h16,
                  AppButton.onBorder(
                    text: "Retry",
                    isShort: true,
                    width: 140,
                    press: () => ref.invalidate(countriesListProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (countries) => _buildForm(countries),
        ),
      ),
    );
  }

  Widget _buildForm(List<DthCountry> countries) {
    final selected = _selectedCountry(countries);
    final fixedStates = selected?.hasFixedStates == true;
    final countryOptions = _countryOptions(countries);
    final stateOptions = _stateOptions(selected);
    final canSave = _canSave(countries);
    final phoneCodeHint = _phoneCountryCodeHint(_phoneController.text);

    final countryValue =
        _countryName != null &&
            countryOptions.any((o) => o.value == _countryName)
        ? _countryName
        : null;
    final stateValue =
        _selectedState != null &&
            stateOptions.any((o) => o.value == _selectedState)
        ? _selectedState
        : null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF6F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          SvgAssets.storeFire,
                          width: 32,
                          height: 32,
                        ),
                        Gap.w8,
                        Expanded(
                          child: AppText.medium(
                            "Kindly ensure your delivery address is correctly entered to avoid hassles.",
                            fontSize: 14,
                            height: 1.35,
                            color: const Color(0xff49597B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap.h20,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          title: "Building No.",
                          hint: "E.g 7",
                          titleSize: 12,
                          titleColor: AppColors.black,
                          controller: _buildingController,
                          focusNode: _buildingFocus,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v.trim().isEmpty) return "Required";
                            if (v.trim().length > 50) {
                              return "Must be 50 characters or less";
                            }
                            return null;
                          },
                        ),
                      ),
                      Gap.w12,
                      Expanded(
                        flex: 5,
                        child: AppTextField(
                          title: "Street Name",
                          hint: "Enter street name",
                          titleSize: 12,
                          titleColor: AppColors.black,
                          controller: _streetController,
                          focusNode: _streetFocus,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v.trim().isEmpty) {
                              return "This field is required";
                            }
                            if (v.trim().length > 255) {
                              return "Must be 255 characters or less";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Gap.h16,
                  AppDropdownFormField<String>(
                    key: ValueKey("country-${countries.length}-$countryValue"),
                    title: "Country",
                    titleSize: 12,
                    hint: "Select country",
                    options: countryOptions,
                    initialValue: countryValue,
                    search: true,
                    onChanged: _onCountryChanged,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Select a country";
                      }
                      return null;
                    },
                  ),
                  Gap.h16,
                  if (fixedStates)
                    AppDropdownFormField<String>(
                      key: ValueKey("state-$_countryName-$stateValue"),
                      title: "State/District",
                      titleSize: 12,
                      hint: "Select state",
                      options: stateOptions,
                      initialValue: stateValue,
                      search: true,
                      enabled: selected != null,
                      onDisabledTap: () {
                        DthFlushBar.instance.showError(
                          title: "Country required",
                          message: "Select a country first.",
                        );
                      },
                      onChanged: (value) {
                        setState(() => _selectedState = value);
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Select a state";
                        }
                        return null;
                      },
                    )
                  else
                    AppTextField(
                      title: "State/District",
                      hint: "Enter state or district",
                      titleSize: 12,
                      titleColor: AppColors.black,
                      controller: _stateController,
                      focusNode: _stateFocus,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v.trim().isEmpty) {
                          return "This field is required";
                        }
                        if (v.trim().length > 100) {
                          return "Must be 100 characters or less";
                        }
                        return null;
                      },
                    ),
                  Gap.h16,
                  AppTextField(
                    title: "City/Town",
                    hint: "Enter city or town",
                    titleSize: 12,
                    titleColor: AppColors.black,
                    controller: _cityController,
                    focusNode: _cityFocus,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v.trim().isEmpty) {
                        return "This field is required";
                      }
                      if (v.trim().length > 100) {
                        return "Must be 100 characters or less";
                      }
                      return null;
                    },
                  ),
                  Gap.h16,
                  AppTextField(
                    title: "Postal Code",
                    hint: "Enter postal code",
                    titleSize: 12,
                    titleColor: AppColors.black,
                    controller: _postalController,
                    focusNode: _postalFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    suffixIcon: _pasteSuffix(_postalController),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 46,
                      minHeight: 24,
                    ),
                    validator: (v) {
                      if (v.trim().isEmpty) {
                        return "This field is required";
                      }
                      if (v.trim().length > 20) {
                        return "Must be 20 characters or less";
                      }
                      return null;
                    },
                  ),
                  Gap.h16,
                  AppTextField(
                    title: "Phone Number",
                    hint: "e.g. +234 901 234 5678",
                    titleSize: 12,
                    titleColor: AppColors.black,
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    suffixIcon: _pasteSuffix(_phoneController),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 46,
                      minHeight: 24,
                    ),
                    validator: (v) {
                      if (v.trim().isEmpty) {
                        return "This field is required";
                      }
                      if (!_hasCountryCode(v)) {
                        return "Include your country code (e.g. +234…)";
                      }
                      if (!_isValidPhone(v)) {
                        return "Enter a valid phone number";
                      }
                      return null;
                    },
                  ),
                  if (phoneCodeHint != null) ...[
                    Gap.h6,
                    AppText.regular(
                      phoneCodeHint,
                      fontSize: 12,
                      color: AppColors.redTint35,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AppButton(
            text: "Save",
            enabled: canSave,
            isLoading: _saving,
            press: canSave ? () => unawaited(_onSave(countries)) : null,
          ),
        ),
      ],
    );
  }
}
