import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/data/data.dart';
import 'package:dth_v4/features/app_web_view/app_web_view.dart';
import 'package:dth_v4/features/authentication/view_model/create_account_view_model.dart';
import 'package:dth_v4/features/authentication/views/login_view.dart';
import 'package:dth_v4/features/authentication/views/verify_otp_view.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_utils/flutter_utils.dart';

class CreateAccountView extends ConsumerStatefulWidget {
  const CreateAccountView({super.key});

  static const String path = NavigatorRoutes.createAccount;

  @override
  ConsumerState<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends ConsumerState<CreateAccountView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final FocusNode _nameFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _phoneFocus;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;
  DthCountry? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    _emailFocus = FocusNode();
    _phoneFocus = FocusNode();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _termsTap = TapGestureRecognizer()..onTap = _onTermsPressed;
    _privacyTap = TapGestureRecognizer()..onTap = _onPrivacyPressed;
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _onTermsPressed() {
    HapticFeedback.lightImpact();
    MobileNavigationService.instance.navigateTo(
      AppWebView.path,
      extra: {
        RoutingArgumentKey.title: 'Terms & Conditions',
        RoutingArgumentKey.initialURl: AppLink.termsAndConditions,
      },
    );
  }

  void _onPrivacyPressed() {
    HapticFeedback.lightImpact();
    MobileNavigationService.instance.navigateTo(
      AppWebView.path,
      extra: {
        RoutingArgumentKey.title: 'Privacy Policy',
        RoutingArgumentKey.initialURl: AppLink.privacyPolicy,
      },
    );
  }

  Future<void> _onCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final country = _selectedCountry;
    if (country == null) {
      DthFlushBar.instance.showError(
        title: 'Phone',
        message: 'Select a country and enter your phone number.',
      );
      return;
    }
    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final phone = composeInternationalPhone(
      country: country,
      nationalInput: _phoneController.text.trim(),
    );
    final model = ref.read(createAccountViewModelProvider);
    final signature = await model.register(
      fullName: fullName,
      email: email,
      isoCode: country.isoCode,
      phone: phone,
    );
    if (signature == null || !mounted) return;
    MobileNavigationService.instance.push(
      VerifyOtpView.path,
      extra: {
        RoutingArgumentKey.email: email,
        RoutingArgumentKey.signature: signature,
        RoutingArgumentKey.otpFlow: OtpFlowArg.register,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<DthCountry>>>(countriesListProvider, (_, next) {
      next.whenData((list) {
        if (!mounted || _selectedCountry != null) return;
        DthCountry? pick;
        for (final c in list) {
          if (c.isoCode == 'NG') {
            pick = c;
            break;
          }
        }
        pick ??= list.isNotEmpty ? list.first : null;
        if (pick != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedCountry = pick);
          });
        }
      });
    });

    final model = ref.watch(createAccountViewModelProvider);
    final theme = Theme.of(context);
    const bodyColor = Color(0xFF6A6A6A);
    const linkColor = AppColors.primary;
    final baseStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: bodyColor,
          fontSize: 12,
          height: 1.45,
        ) ??
        TextStyle(color: bodyColor, fontSize: 12, height: 1.45);
    final linkStyle = baseStyle.copyWith(
      color: linkColor,
      fontWeight: FontWeight.w400,
      fontSize: 12,
    );
    final blackStyle = baseStyle.copyWith(
      color: AppColors.black,
      fontWeight: FontWeight.w400,
      fontSize: 12,
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gap.h14,
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        Gap.h10,
                        AppText.medium(
                          'Create account for free',
                          fontSize: 24,
                          letterSpacing: -0.4,
                          color: const Color(0xff08102F),
                        ),
                        Gap.h8,
                        AppText.regular(
                          'Enter your email to sign up for the most exciting Talent Hunt show in Africa.',
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.paleLavender,
                        ),
                        Gap.h24,
                        AppTextField(
                          title: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _nameController,
                          focusNode: _nameFocus,
                          validator: Validator.fullname,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_emailFocus),
                          formatter: [
                            FilteringTextInputFormatter.singleLineFormatter,
                          ],
                        ),
                        Gap.h16,
                        AppTextField(
                          title: 'Email Address',
                          hint: 'example@email.com',
                          controller: _emailController,
                          focusNode: _emailFocus,
                          validator: Validator.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_phoneFocus),
                          formatter: [
                            FilteringTextInputFormatter.singleLineFormatter,
                          ],
                        ),
                        Gap.h16,
                        PhoneNumberCountryInput(
                          title: 'Phone Number',
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          displayCountry: _selectedCountry,
                          textInputAction: TextInputAction.done,
                          onCountryTap: () {
                            showCountryPickerBottomSheet(
                              context,
                              initialCountry: _selectedCountry,
                              onSelected: (c) =>
                                  setState(() => _selectedCountry = c),
                            );
                          },
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          validator: (v) =>
                              validateNationalPhone(v, _selectedCountry),
                        ),
                        Gap.h28,
                      ],
                    ),
                  ),
                ),

                AppButton.primary(
                  text: 'Create account',
                  isLoading: model.isBaseBusy,
                  enabled: !model.isBaseBusy,
                  press: _onCreateAccount,
                ),
                Gap.h12,
                AppButton.onBorder(
                  text: 'I have an account',
                  textColor: AppColors.primary,
                  borderColor: AppColors.primary,
                  press: () {
                    MobileNavigationService.instance.navigateAndClearStack(
                      LoginView.path,
                    );
                  },
                ),
                Gap.h24,
                Text.rich(
                  TextSpan(
                    style: baseStyle,
                    children: [
                      const TextSpan(text: 'By clicking '),
                      TextSpan(text: '"Continue" ', style: blackStyle),
                      const TextSpan(text: 'you acknowledge and agree to '),
                      TextSpan(
                        text: "DTH's Terms & Conditions",
                        style: linkStyle,
                        recognizer: _termsTap,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy.',
                        style: linkStyle,
                        recognizer: _privacyTap,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                Gap.h16,
                Gap.h16,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
