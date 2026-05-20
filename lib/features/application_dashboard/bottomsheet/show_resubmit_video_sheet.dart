import "dart:async";

import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<void> showResubmitVideoSheet(
  BuildContext context, {
  required Future<void> Function(String videoLink, String socialMediaLink)
  onSubmit,
}) {
  return showBlurredModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ResubmitVideoSheetBody(onSubmit: onSubmit),
  );
}

String? _validateHttpUrl(String value) {
  final t = value.trim();
  if (t.isEmpty) return "This field is required";
  final uri = Uri.tryParse(t);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return "Enter a valid URL";
  }
  return null;
}

class _ResubmitVideoSheetBody extends StatefulWidget {
  const _ResubmitVideoSheetBody({required this.onSubmit});

  final Future<void> Function(String videoLink, String socialMediaLink)
  onSubmit;

  @override
  State<_ResubmitVideoSheetBody> createState() =>
      _ResubmitVideoSheetBodyState();
}

class _ResubmitVideoSheetBodyState extends State<_ResubmitVideoSheetBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _socialController;
  late final TextEditingController _videoController;
  late final FocusNode _socialFocus;
  late final FocusNode _videoFocus;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _socialController = TextEditingController();
    _videoController = TextEditingController();
    _socialFocus = FocusNode();
    _videoFocus = FocusNode();
  }

  @override
  void dispose() {
    _socialController.dispose();
    _videoController.dispose();
    _socialFocus.dispose();
    _videoFocus.dispose();
    super.dispose();
  }

  Future<void> _pasteInto(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    if (!mounted) return;
    setState(() => controller.text = text);
  }

  Widget _pasteSuffix(TextEditingController controller) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await _pasteInto(controller);
      },
      child: AppText.regular("PASTE", fontSize: 10, color: AppColors.black),
    );
  }

  Future<void> _onSubmit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        _videoController.text.trim(),
        _socialController.text.trim(),
      );
    } on ApiFailure {
      // Caller shows error flush bar.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: AppColors.greyTint20,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).maybePop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.mainBlack,
                      ),
                    ),
                  ),
                ),
              ),
              Gap.h4,
              AppText.medium(
                "You're Almost Done",
                fontSize: 14,
                color: AppColors.black,
                textAlign: TextAlign.center,
              ),
              Gap.h8,
              AppText.regular(
                "Add your updated audition video and social media link to continue your application.",
                fontSize: 12,
                height: 1.35,
                color: AppColors.blackTint20,
                textAlign: TextAlign.center,
                multiText: true,
              ),
              Gap.h24,
              AppTextField(
                title: "Social Media Link",
                hint: "https://www.example.com/your_handle",
                controller: _socialController,
                focusNode: _socialFocus,
                titleColor: AppColors.black,
                validator: _validateHttpUrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                formatter: [FilteringTextInputFormatter.singleLineFormatter],
                suffixIcon: _pasteSuffix(_socialController),
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_videoFocus);
                },
              ),
              Gap.h16,
              AppTextField(
                title: "Video Link",
                hint: "https://www.example.com/audition_video",
                controller: _videoController,
                focusNode: _videoFocus,
                titleColor: AppColors.black,
                validator: _validateHttpUrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                formatter: [FilteringTextInputFormatter.singleLineFormatter],
                suffixIcon: _pasteSuffix(_videoController),
                onSubmitted: (_) => unawaited(_onSubmit()),
              ),
              Gap.h24,
              AppButton.primary(
                text: "Submit",
                width: double.infinity,
                height: 48,
                radius: 100,
                enabled: !_busy,
                isLoading: _busy,
                press: () => unawaited(_onSubmit()),
              ),
              Gap.h20,
            ],
          ),
        ),
      ),
    );
  }
}
