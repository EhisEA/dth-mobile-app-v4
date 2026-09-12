import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/profile/bank_account/view_model/bank_account_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class AddBankAccountView extends ConsumerStatefulWidget {
  const AddBankAccountView({super.key});

  static const String path = NavigatorRoutes.addBankAccount;

  @override
  ConsumerState<AddBankAccountView> createState() => _AddBankAccountViewState();
}

class _AddBankAccountViewState extends ConsumerState<AddBankAccountView> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberFocus = FocusNode();
  final _accountNameFocus = FocusNode();

  String? _bankUid;
  Timer? _resolveDebounce;
  int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    _accountNumberController.addListener(_onAccountNumberChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(bankAccountViewModelProvider).loadBanks());
    });
  }

  @override
  void dispose() {
    _resolveDebounce?.cancel();
    _accountNumberController.removeListener(_onAccountNumberChanged);
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _accountNumberFocus.dispose();
    _accountNameFocus.dispose();
    super.dispose();
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r"\D"), "");

  void _onAccountNumberChanged() {
    _scheduleResolve();
  }

  void _onBankChanged(String? uid) {
    setState(() => _bankUid = uid);
    _accountNameController.clear();
    _scheduleResolve();
  }

  void _scheduleResolve() {
    _resolveDebounce?.cancel();
    final bankUid = _bankUid?.trim() ?? "";
    final digits = _digitsOnly(_accountNumberController.text);
    if (bankUid.isEmpty || digits.length != 10) {
      if (_accountNameController.text.isNotEmpty) {
        _accountNameController.clear();
      }
      return;
    }
    _resolveDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_resolve(bankUid: bankUid, accountNumber: digits));
    });
  }

  Future<void> _resolve({
    required String bankUid,
    required String accountNumber,
  }) async {
    final gen = ++_resolveGeneration;
    final name = await ref
        .read(bankAccountViewModelProvider)
        .resolveAccountName(bankUid: bankUid, accountNumber: accountNumber);
    if (!mounted || gen != _resolveGeneration) return;
    if (name == null || name.isEmpty) {
      _accountNameController.clear();
      setState(() {});
      return;
    }
    _accountNameController.text = name;
    setState(() {});
  }

  Future<void> _pasteAccountNumber() async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? "";
    if (text.isEmpty) return;
    final digits = _digitsOnly(text);
    if (digits.isEmpty) return;
    _accountNumberController.text = digits;
    _accountNumberController.selection = TextSelection.collapsed(
      offset: digits.length,
    );
    setState(() {});
  }

  Widget _pasteSuffix() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pasteAccountNumber,
      child: AppText.medium("PASTE", fontSize: 12, color: AppColors.black),
    );
  }

  Future<void> _onSave() async {
    HapticFeedback.lightImpact();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final bankUid = _bankUid?.trim() ?? "";
    if (bankUid.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Bank required",
        message: "Please select a bank.",
      );
      return;
    }
    final accountName = _accountNameController.text.trim();
    if (accountName.isEmpty) {
      DthFlushBar.instance.showError(
        title: "Account name",
        message: "Resolve a valid account number before saving.",
      );
      return;
    }

    final ok = await ref
        .read(bankAccountViewModelProvider)
        .addBankAccount(
          bankUid: bankUid,
          accountNumber: _digitsOnly(_accountNumberController.text),
          accountName: accountName,
        );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(bankAccountViewModelProvider);
    final bankOptions = [
      for (final bank in vm.banks)
        AppDropdownOption(value: bank.uid, label: bank.name),
    ];

    return Loader.page(
      isLoading: vm.isBaseBusy,
      child: Scaffold(
        appBar: const DthAppBar(title: ""),
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Gap.h8,
                        AppText.medium(
                          "Add bank account",
                          fontSize: 22,
                          letterSpacing: -0.4,
                          color: AppColors.tertiary60,
                          height: 1.3,
                        ),
                        Gap.h4,
                        AppText.regular(
                          "Enter your bank account details",
                          fontSize: 14,
                          color: AppColors.tint25,
                        ),
                        Gap.h24,
                        AppDropdownFormField<String>(
                          title: "Bank Name",
                          titleSize: 12,
                          hint: vm.banksLoading
                              ? "Loading banks..."
                              : "Select bank",
                          options: bankOptions,
                          search: true,
                          enabled: !vm.banksLoading && bankOptions.isNotEmpty,
                          onChanged: _onBankChanged,
                        ),
                        Gap.h16,
                        AppTextField(
                          title: "Account Number",
                          hint: "Enter account number",
                          titleSize: 12,
                          controller: _accountNumberController,
                          focusNode: _accountNumberFocus,
                          titleColor: AppColors.black,
                          keyboardType: TextInputType.number,
                          formatter: [FilteringTextInputFormatter.digitsOnly],
                          textInputAction: TextInputAction.next,
                          suffixIcon: _pasteSuffix(),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 46,
                            minHeight: 24,
                          ),
                          validator: (v) {
                            final d = _digitsOnly(v);
                            if (d.isEmpty) return "This field is required";
                            if (d.length != 10) {
                              return "Enter a valid 10-digit account number";
                            }
                            return null;
                          },
                        ),
                        Gap.h16,
                        AppTextField(
                          title: "Account Name",
                          hint: vm.resolving
                              ? "Resolving..."
                              : "Account name appears after resolve",
                          controller: _accountNameController,
                          enabled: false,
                          titleSize: 12,
                          readOnly: true,
                          focusNode: _accountNameFocus,
                          titleColor: AppColors.black,
                          textInputAction: TextInputAction.done,
                          validator: (v) {
                            if (v.trim().isEmpty) {
                              return "Resolve a valid account number first";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AppButton.primary(
                  fontSize: 14,
                  text: "Save",
                  isShort: true,
                  press: _onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
