import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/application_process_models.dart";
import "package:dth_v4/data/models/application_wizard_inputs.dart";
import "package:dth_v4/features/application/view_model/application_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class BankDetailsStep extends ConsumerStatefulWidget {
  const BankDetailsStep({
    super.key,
    required this.formKey,
    required this.onRegisterPersist,
    required this.applicationProcess,
  });

  final GlobalKey<FormState> formKey;
  final void Function(void Function() persist) onRegisterPersist;
  final ApplicationProcess applicationProcess;

  @override
  ConsumerState<BankDetailsStep> createState() => _BankDetailsStepState();
}

class _BankDetailsStepState extends ConsumerState<BankDetailsStep>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final FocusNode _accountFocus;
  late final FocusNode _accountNameFocus;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountNameController;

  String? _bankName;
  // Automatic account-name resolution (stub) — disabled; user enters account name.
  // String _lastResolvedForDigits = '';
  // int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    _accountFocus = FocusNode();
    _accountNameFocus = FocusNode();
    _accountNumberController = TextEditingController();
    _accountNameController = TextEditingController();
    // _accountNumberController.addListener(_onAccountNumberChanged);
    widget.onRegisterPersist(_persist);
  }

  @override
  void dispose() {
    // _accountNumberController.removeListener(_onAccountNumberChanged);
    _accountFocus.dispose();
    _accountNameFocus.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  // void _onAccountNumberChanged() {
  //   final digits = _digitsOnly(_accountNumberController.text);
  //   if (digits.length != 10) {
  //     if (_accountNameController.text.isNotEmpty) {
  //       _accountNameController.clear();
  //     }
  //     _lastResolvedForDigits = '';
  //     setState(() {});
  //     return;
  //   }
  //   if (digits == _lastResolvedForDigits) return;
  //   _resolveAccountStub(digits);
  // }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  // Future<void> _resolveAccountStub(String tenDigits) async {
  //   final gen = ++_resolveGeneration;
  //   await Future<void>.delayed(const Duration(milliseconds: 450));
  //   if (!mounted || gen != _resolveGeneration) return;
  //   if (_digitsOnly(_accountNumberController.text) != tenDigits) return;
  //   _lastResolvedForDigits = tenDigits;
  //   final draft = ref.read(applicationViewModelProvider).draft;
  //   final holder = draft.fullName.trim().isNotEmpty
  //       ? draft.fullName.trim()
  //       : 'Example Doe';
  //   setState(() {
  //     _accountNameController.text = holder;
  //   });
  //   widget.formKey.currentState?.validate();
  // }

  void _persist() {
    ref
        .read(applicationViewModelProvider)
        .setBankDetails(
          BankDetailsInput(
            bankName: _bankName ?? '',
            accountNumber: _digitsOnly(_accountNumberController.text),
            accountName: _accountNameController.text.trim(),
          ),
        );
  }

  String? _accountNameValidator(String value) {
    if (_digitsOnly(_accountNumberController.text).length != 10) {
      return null;
    }
    if (value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bankOptions = [
      for (final bank in widget.applicationProcess.banks)
        AppDropdownOption(value: bank, label: bank),
    ];

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          AppText.medium(
            'Bank Details',
            fontSize: 24,
            letterSpacing: -0.4,
            color: AppColors.tertiary60,
          ),
          Gap.h8,
          AppText.regular(
            "Add your bank details to enable payments if you're selected.",
            fontSize: 14,
            height: 1.4,
            color: AppColors.blackTint20,
          ),
          Gap.h24,
          AppDropdownFormField<String>(
            title: 'Bank Name',
            hint: 'select bank',
            options: bankOptions,
            search: true,
            onChanged: (v) => setState(() => _bankName = v),
          ),
          Gap.h16,
          AppTextField(
            title: 'Account Number',
            hint: 'Enter account number',
            controller: _accountNumberController,
            focusNode: _accountFocus,
            titleColor: AppColors.black,
            keyboardType: TextInputType.number,
            validator: (v) {
              final d = _digitsOnly(v);
              if (d.isEmpty) return 'This field is required';
              if (d.length != 10) {
                return 'Enter a valid 10-digit account number';
              }
              return null;
            },
            formatter: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
          ),
          Gap.h16,
          AppTextField(
            title: 'Account Name',
            hint: 'Enter name as on bank account',
            controller: _accountNameController,
            focusNode: _accountNameFocus,
            titleColor: AppColors.black,
            validator: _accountNameValidator,
            textInputAction: TextInputAction.done,
          ),
          Gap.h32,
        ],
      ),
    );
  }
}
