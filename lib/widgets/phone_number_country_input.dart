import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/dth_country.dart";
import "package:dth_v4/widgets/country_flag_thumbnail.dart";
import "package:dth_v4/widgets/text/app_text.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Validates the national number in [value] (no dial code in the string).
String? validateNationalPhone(String value, DthCountry? country) {
  final empty = Validator.emptyField(value, "Phone number");
  if (empty != null) return empty;
  final digits = value.replaceAll(RegExp(r"\D"), "");
  if (country != null && country.isoCode == "NG") {
    return Validator.phone(digits);
  }
  if (digits.length < 7 || digits.length > 15) {
    return "Enter a valid phone number";
  }
  return null;
}

/// Builds E.164-style storage: dial code + national digits only.
String composeInternationalPhone({
  required DthCountry? country,
  required String nationalInput,
}) {
  final dial = country?.dialCode ?? "";
  final digits = nationalInput.replaceAll(RegExp(r"\D"), "");
  return "$dial$digits";
}

String _digitsOnly(String s) => s.replaceAll(RegExp(r"\D"), "");

/// Removes [country]’s dial prefix from [storedPhone] when it is full
/// international form (e.g. `+2349020971619` → `9020971619`).
String nationalDigitsWithoutDialCode({
  required String storedPhone,
  required DthCountry? country,
}) {
  final all = _digitsOnly(storedPhone);
  if (country == null) return all;
  final dial = _digitsOnly(country.dialCode);
  if (dial.isEmpty) return all;
  if (all.startsWith(dial) && all.length > dial.length) {
    return all.substring(dial.length);
  }
  return all;
}

/// Nigerian numbers sometimes include a trunk `0` after the country code.
String _normalizeNationalTrunk(String national, DthCountry? country) {
  if (country?.isoCode != "NG") return national;
  if (national.length == 11 && national.startsWith("0")) {
    return national.substring(1);
  }
  return national;
}

/// Spaces for display in the national field (dial code is shown separately).
String formatNationalPhoneDisplay(String nationalDigits) {
  final d = _digitsOnly(nationalDigits);
  if (d.isEmpty) return "";
  if (d.length == 10) {
    return "${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}";
  }
  if (d.length == 9) {
    return "${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}";
  }
  final buf = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i != 0 && i % 3 == 0) buf.write(" ");
    buf.write(d[i]);
  }
  return buf.toString();
}

/// Read-only field text: strip stored international prefix, normalize, space.
String displayNationalPhoneInField({
  required String storedPhone,
  required DthCountry? country,
}) {
  var national = nationalDigitsWithoutDialCode(
    storedPhone: storedPhone,
    country: country,
  );
  national = _normalizeNationalTrunk(national, country);
  return formatNationalPhoneDisplay(national);
}

class PhoneNumberCountryInput extends StatefulWidget {
  const PhoneNumberCountryInput({
    super.key,
    this.controller,
    this.focusNode,
    this.displayCountry,
    this.textInputAction,
    this.onCountryTap,
    this.onSubmitted,
    this.title = "Phone Number",
    this.hint = "702 3456 789",
    this.validator,
    this.formatter,
    this.readOnly = false,
    this.lockCountryPicker = false,
    this.suffix,
    this.initialNationalDigits,
  });

  /// When null in editable mode, assert fails. When [readOnly] is true, either
  /// pass a [controller] or [initialNationalDigits] (an internal controller is created).
  final TextEditingController? controller;

  /// When null, an internal [FocusNode] is created and disposed by this widget.
  final FocusNode? focusNode;

  final DthCountry? displayCountry;
  final TextInputAction? textInputAction;
  final VoidCallback? onCountryTap;
  final ValueChanged<String>? onSubmitted;
  final String title;
  final String hint;
  final String? Function(String value)? validator;
  final List<TextInputFormatter>? formatter;
  final bool readOnly;

  /// When true, country flag/dial code are fixed (no chevron, no tap).
  final bool lockCountryPicker;

  /// Shown at the end of the input row (e.g. “Verify Now”).
  final Widget? suffix;

  /// Used only when [controller] is null and [readOnly] is true.
  final String? initialNationalDigits;

  @override
  State<PhoneNumberCountryInput> createState() =>
      _PhoneNumberCountryInputState();
}

class _PhoneNumberCountryInputState extends State<PhoneNumberCountryInput> {
  String? _errorText;
  bool _focused = false;

  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;

  static const _radius = 12.0;
  static const _borderIdle = Color(0xffEDEDED);
  static const _hintColor = Color(0xffB5B5B5);

  TextEditingController get _effectiveController =>
      widget.controller ?? _ownedController!;

  FocusNode get _effectiveFocus => widget.focusNode ?? _ownedFocus!;

  @override
  void initState() {
    super.initState();
    assert(
      widget.readOnly || widget.controller != null,
      "Editable PhoneNumberCountryInput requires a controller.",
    );
    assert(
      !widget.readOnly ||
          widget.controller != null ||
          widget.initialNationalDigits != null,
      "Read-only PhoneNumberCountryInput needs a controller or initialNationalDigits.",
    );

    if (widget.controller == null) {
      final initial = widget.readOnly
          ? displayNationalPhoneInField(
              storedPhone: widget.initialNationalDigits ?? "",
              country: widget.displayCountry,
            )
          : (widget.initialNationalDigits ?? "");
      _ownedController = TextEditingController(text: initial);
    }
    if (widget.focusNode == null) {
      _ownedFocus = FocusNode();
    }
    _effectiveFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _effectiveFocus.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _ownedFocus?.dispose();
    }
    if (widget.controller == null) {
      _ownedController?.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    final has = _effectiveFocus.hasFocus;
    if (_focused != has) {
      setState(() => _focused = has);
    }
  }

  @override
  void didUpdateWidget(covariant PhoneNumberCountryInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.readOnly || widget.controller != null) return;
    final sameSource =
        oldWidget.initialNationalDigits == widget.initialNationalDigits &&
        oldWidget.displayCountry?.isoCode == widget.displayCountry?.isoCode &&
        oldWidget.displayCountry?.dialCode == widget.displayCountry?.dialCode;
    if (sameSource) return;
    final next = displayNationalPhoneInField(
      storedPhone: widget.initialNationalDigits ?? "",
      country: widget.displayCountry,
    );
    if (_ownedController != null && _ownedController!.text != next) {
      _ownedController!.text = next;
    }
  }

  Color _borderColor() {
    if (_errorText != null) return Colors.red;
    if (widget.readOnly) return _borderIdle;
    if (_focused) return AppColors.primary;
    return _borderIdle;
  }

  @override
  Widget build(BuildContext context) {
    final textAction = widget.textInputAction ?? TextInputAction.done;
    final showChevron =
        !widget.lockCountryPicker &&
        (!widget.readOnly || widget.onCountryTap != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _borderColor()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.regular(
                widget.title,
                fontSize: 10,
                letterSpacing: -0.2,
                color: AppColors.tint15,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.lockCountryPicker
                          ? null
                          : widget.readOnly
                          ? widget.onCountryTap
                          : (widget.onCountryTap ?? () {}),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.displayCountry != null &&
                                widget.displayCountry!.flagDataUri.isNotEmpty)
                              CountryFlagThumbnail(
                                flagDataUri: widget.displayCountry!.flagDataUri,
                              )
                            else
                              Container(
                                height: 22,
                                width: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.greyTint30,
                                ),
                              ),
                            Gap.w6,
                            AppText.regular(
                              widget.displayCountry?.dialCode ?? "",
                              fontSize: 14,
                              color: AppColors.black,
                            ),
                            if (showChevron) ...[
                              Gap.w4,
                              SvgPicture.asset(
                                SvgAssets.downArrow,
                                width: 12,
                                height: 12,
                                colorFilter: ColorFilter.mode(
                                  AppColors.blackTint20,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Gap.w8,
                  Expanded(
                    child: TextFormField(
                      controller: _effectiveController,
                      focusNode: _effectiveFocus,
                      readOnly: widget.readOnly,
                      keyboardType: TextInputType.phone,
                      textInputAction: textAction,
                      onFieldSubmitted: widget.onSubmitted ?? (_) {},
                      style: AppTextStyle.regular.copyWith(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                      cursorColor: AppColors.primary,
                      inputFormatters: widget.readOnly
                          ? const []
                          : (widget.formatter ??
                                [FilteringTextInputFormatter.digitsOnly]),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        hintText: widget.hint,
                        hintStyle: AppTextStyle.regular.copyWith(
                          fontSize: 14,
                          color: _hintColor,
                        ),
                        contentPadding: EdgeInsets.zero,
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                      ),
                      validator: widget.readOnly
                          ? null
                          : (value) {
                              String? err;
                              if (widget.validator != null) {
                                err = widget.validator!(value ?? "");
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                final next = err;
                                if (_errorText != next) {
                                  setState(() => _errorText = next);
                                }
                              });
                              return err;
                            },
                    ),
                  ),
                  if (widget.suffix != null) ...[
                    Gap.w8,
                    Align(
                      alignment: Alignment.center,
                      widthFactor: 1,
                      heightFactor: 1,
                      child: widget.suffix!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (!widget.readOnly && _errorText != null && _errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: AppText.regular(
              _errorText!.capitalizeFirstLetter(),
              fontSize: 12,
              color: Colors.red,
            ),
          ),
      ],
    );
  }
}
