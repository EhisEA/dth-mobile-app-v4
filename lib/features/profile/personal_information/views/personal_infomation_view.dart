import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/profile/personal_information/view_model/personal_information_view_model.dart";
import "package:dth_v4/features/profile/profile.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class PersonalInfomationView extends ConsumerStatefulWidget {
  const PersonalInfomationView({super.key});

  static const String path = NavigatorRoutes.personalInformation;

  @override
  ConsumerState<PersonalInfomationView> createState() =>
      _PersonalInfomationViewState();
}

class _PersonalInfomationViewState
    extends ConsumerState<PersonalInfomationView> {
  bool _editingProfile = false;
  DthCountry? _editCountry;

  late final TextEditingController _nameController;
  late final FocusNode _nameFocus;
  late final TextEditingController _phoneController;
  late final FocusNode _phoneFocus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocus = FocusNode();
    _phoneController = TextEditingController();
    _phoneFocus = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _startEditingProfile(UserModel u, DthCountry? displayCountry) {
    final countries = ref
        .read(countriesListProvider)
        .maybeWhen(data: (list) => list, orElse: () => null);
    if (countries == null || countries.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Please wait",
        message: "Country list is still loading. Try again in a moment.",
      );
      return;
    }
    // Google-auth users skip phone collection at sign-up, so [u.isoCode] can
    // be empty. Fall back to Nigeria (the app's default — same pick as the
    // create-account form) and then the first available country, so the user
    // can still enter edit mode and choose their own country from the picker.
    final country = displayCountry ??
        DthCountry.findByIso(countries, u.isoCode) ??
        DthCountry.findByIso(countries, "NG") ??
        countries.first;
    setState(() {
      _editingProfile = true;
      _editCountry = country;
      _nameController.text = u.fullName.trim();
      _phoneController.text = displayNationalPhoneInField(
        storedPhone: u.phoneNumber,
        country: country,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocus.requestFocus();
      }
    });
  }

  Future<void> _saveProfileEdits() async {
    final vm = ref.read(personalInformationViewModelProvider);
    final nameErr = Validator.fullname(_nameController.text);
    if (nameErr != null) {
      DthFlushBar.instance.showError(title: "Name", message: nameErr);
      return;
    }
    final country = _editCountry;
    if (country == null) {
      DthFlushBar.instance.showError(
        title: "Country",
        message: "Select a country for your phone number.",
      );
      return;
    }
    final phoneErr = validateNationalPhone(_phoneController.text, country);
    if (phoneErr != null) {
      DthFlushBar.instance.showError(title: "Phone", message: phoneErr);
      return;
    }
    final phone = composeInternationalPhone(
      country: country,
      nationalInput: _phoneController.text,
    );
    final ok = await vm.saveProfileDetails(
      fullName: _nameController.text.trim(),
      phone: phone,
      isoCode: country.isoCode,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _editingProfile = false);
    }
  }

  Widget _profileBottomBar(
    PersonalInformationViewModel vm,
    UserModel u,
    DthCountry? displayCountry,
  ) {
    if (!_editingProfile) {
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: AppButton.primary(
          text: "Edit",
          press: () => _startEditingProfile(u, displayCountry),
        ),
      );
    }
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ValueListenableBuilder<bool>(
        valueListenable: vm.savingProfile,
        builder: (context, saving, _) {
          return Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  text: "Cancel",
                  enabled: !saving,
                  press: saving
                      ? () {}
                      : () => setState(() => _editingProfile = false),
                ),
              ),
              Gap.w12,
              Expanded(
                child: AppButton.primary(
                  text: "Save",
                  enabled: !saving,
                  isLoading: saving,
                  press: () => unawaited(_saveProfileEdits()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(personalInformationViewModelProvider);
    final userState = ref.watch(userStateProvider);

    return Loader.page(
      isLoading: vm.isBlockingPageBusy && !_editingProfile,
      child: ValueListenableBuilder<UserModel?>(
        valueListenable: userState.user,
        builder: (context, user, _) {
          if (user == null) {
            return Scaffold(
              appBar: DthAppBar(title: "Personal Information"),
              backgroundColor: AppColors.scaffold,
              body: const Center(child: CircularProgressIndicator.adaptive()),
            );
          }
          final u = user;
          final displayCountry = ref
              .watch(countriesListProvider)
              .maybeWhen(
                data: (countries) => DthCountry.findByIso(countries, u.isoCode),
                orElse: () => null,
              );
          return Scaffold(
            appBar: DthAppBar(title: "Personal Information"),
            backgroundColor: AppColors.white,
            bottomNavigationBar: Material(
              color: AppColors.scaffold,
              child: _profileBottomBar(vm, u, displayCountry),
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              children: [
                Center(
                  child: ProfileImageWidget(
                    showEdit: !_editingProfile,
                    avatar: u.avatar,
                    onEditTap: () =>
                        unawaited(vm.pickAndUpdateProfileAvatar(u)),
                  ),
                ),
                Gap.h16,
                AppText.semiBold(
                  u.fullName,
                  centered: true,
                  fontSize: 18,
                  color: AppColors.mainBlack,
                ),
                Gap.h2,
                AppText.regular(
                  u.email,
                  centered: true,
                  fontSize: 12,
                  color: AppColors.tint15,
                ),
                Center(child: ContestantPill(user: u)),
                // Gap.h24,
                AppTextField(
                  key: ValueKey<bool>(_editingProfile),
                  title: "Full Name",
                  titleColor: AppColors.tint15,
                  hint: u.fullName,
                  hintColor: AppColors.black,
                  controller: _editingProfile ? _nameController : null,
                  focusNode: _nameFocus,
                  enabled: _editingProfile,
                  readOnly: !_editingProfile,
                  maxLength: _editingProfile
                      ? PersonalInformationViewModel.maxFullNameLength
                      : null,
                  textCapitalization: _editingProfile
                      ? TextCapitalization.words
                      : TextCapitalization.none,
                  formatter: _editingProfile
                      ? [FilteringTextInputFormatter.singleLineFormatter]
                      : const [],
                  textInputAction: _editingProfile
                      ? TextInputAction.next
                      : TextInputAction.done,
                ),
                Gap.h12,
                AppTextField(
                  title: "Email Address",
                  titleColor: AppColors.tint15,
                  hint: u.email,
                  hintColor: AppColors.black,
                  enabled: false,
                  readOnly: true,
                ),
                Gap.h12,
                PhoneNumberCountryInput(
                  key: ValueKey<bool>(_editingProfile),
                  readOnly: !_editingProfile,
                  controller: _editingProfile ? _phoneController : null,
                  focusNode: _editingProfile ? _phoneFocus : null,
                  initialNationalDigits: _editingProfile ? null : u.phoneNumber,
                  displayCountry: _editingProfile
                      ? (_editCountry ?? displayCountry)
                      : displayCountry,
                  textInputAction: _editingProfile
                      ? TextInputAction.done
                      : TextInputAction.done,
                  onCountryTap: _editingProfile
                      ? () {
                          showCountryPickerBottomSheet(
                            context,
                            initialCountry: _editCountry ?? displayCountry,
                            onSelected: (c) => setState(() => _editCountry = c),
                          );
                        }
                      : null,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  validator: _editingProfile
                      ? (v) => validateNationalPhone(v, _editCountry)
                      : null,
                  suffix: (!_editingProfile && !u.isPhoneVerified)
                      ? AppButton.primary(
                          height: 32,
                          width: 76,
                          text: "Verify Now",
                          radius: 30,
                          fontSize: 11,
                          isLoading: vm.isBaseBusy,
                          fontWeight: FontWeight.w400,
                          press: u.phoneNumber.trim().isEmpty
                              ? () {}
                              : () async {
                                  final sent = await vm
                                      .sendPhoneVerificationCode(
                                        u.phoneNumber.trim(),
                                      );
                                  if (!mounted || !sent) return;
                                  MobileNavigationService.instance.push(
                                    ProfilePhoneVerifyOtpView.path,
                                  );
                                },
                        )
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
