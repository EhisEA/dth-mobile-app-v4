import 'package:dth_v4/core/core.dart';
import 'package:dth_v4/features/authentication/view_model/login_view_model.dart';
import 'package:dth_v4/features/authentication/views/create_account_view.dart';
import 'package:dth_v4/features/authentication/views/verify_otp_view.dart';
import 'package:dth_v4/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_utils/flutter_utils.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  static const String path = NavigatorRoutes.login;

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final FocusNode _emailFocus;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailFocus = FocusNode();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final model = ref.read(loginViewModelProvider);
    final signature = await model.login(email: email);
    if (signature == null || !mounted) return;
    MobileNavigationService.instance.push(
      VerifyOtpView.path,
      extra: {
        RoutingArgumentKey.email: email,
        RoutingArgumentKey.signature: signature,
        RoutingArgumentKey.otpFlow: OtpFlowArg.login,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(loginViewModelProvider);
    return Scaffold(
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
                        'Glad to have you back',
                        fontSize: 24,
                        color: const Color(0xff08102F),
                      ),
                      Gap.h8,
                      AppText.regular(
                        'Enter your email to continue from where you left off.',
                        fontSize: 14,
                        color: AppColors.paleLavender,
                      ),
                      Gap.h24,
                      AppTextField(
                        title: 'Email Address',
                        hint: 'example@email.com',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        validator: Validator.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        formatter: [
                          FilteringTextInputFormatter.singleLineFormatter,
                        ],
                      ),
                      Gap.h28,
                    ],
                  ),
                ),
              ),
              AppButton.primary(
                text: 'Login',
                isLoading: model.isBaseBusy,
                enabled: !model.isBaseBusy,
                press: _onLogin,
              ),
              Gap.h12,
              AppButton.onBorder(
                text: "I don't have an account",
                textColor: AppColors.primary,
                borderColor: AppColors.primary,
                press: () => MobileNavigationService.instance
                    .navigateAndClearStack(CreateAccountView.path),
              ),
              Gap.h24,
            ],
          ),
        ),
      ),
    );
  }
}
