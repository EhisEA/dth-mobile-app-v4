import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/models/application_wizard_inputs.dart";
import "package:dth_v4/features/application/view_model/application_view_model.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class AuditionVideoStep extends ConsumerStatefulWidget {
  const AuditionVideoStep({
    super.key,
    required this.formKey,
    required this.onRegisterPersist,
  });

  final GlobalKey<FormState> formKey;
  final void Function(void Function() persist) onRegisterPersist;

  @override
  ConsumerState<AuditionVideoStep> createState() => _AuditionVideoStepState();
}

class _AuditionVideoStepState extends ConsumerState<AuditionVideoStep>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final FocusNode _videoFocus;
  late final FocusNode _socialFocus;
  late final TextEditingController _videoController;
  late final TextEditingController _socialController;

  @override
  void initState() {
    super.initState();
    _videoFocus = FocusNode();
    _socialFocus = FocusNode();
    _videoController = TextEditingController();
    _socialController = TextEditingController();
    widget.onRegisterPersist(_persist);
  }

  @override
  void dispose() {
    _videoFocus.dispose();
    _socialFocus.dispose();
    _videoController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  void _persist() {
    ref
        .read(applicationViewModelProvider)
        .setAuditionVideo(
          AuditionVideoInput(
            videoLink: _videoController.text.trim(),
            socialMediaLink: _socialController.text.trim(),
          ),
        );
  }

  String? _urlValidator(String value) {
    final t = value.trim();
    if (t.isEmpty) return 'This field is required';
    final uri = Uri.tryParse(t);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid URL';
    }
    return null;
  }

  Future<void> _pasteInto(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    if (!mounted) return;
    setState(() {
      controller.text = text;
    });
  }

  Widget _pasteSuffix(TextEditingController controller) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await _pasteInto(controller);
      },
      child: AppText.regular('PASTE', fontSize: 10, color: AppColors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          AppText.medium(
            'Audition Video',
            fontSize: 24,
            letterSpacing: -0.4,
            color: AppColors.tertiary60,
          ),
          Gap.h8,
          AppText.regular(
            'Share your audition video link and a social media profile so we can review your work.',
            fontSize: 14,
            height: 1.4,
            color: AppColors.blackTint20,
          ),
          Gap.h24,
          AppTextField(
            title: 'Video Link',
            hint: 'https://example.com/audition_video',
            controller: _videoController,
            focusNode: _videoFocus,
            titleColor: AppColors.black,
            validator: _urlValidator,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            formatter: [FilteringTextInputFormatter.singleLineFormatter],
            suffixIcon: _pasteSuffix(_videoController),
          ),
          Gap.h16,
          AppTextField(
            title: 'Social Media',
            hint: 'https://example.com/actor',
            controller: _socialController,
            focusNode: _socialFocus,
            titleColor: AppColors.black,
            validator: _urlValidator,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            formatter: [FilteringTextInputFormatter.singleLineFormatter],
            suffixIcon: _pasteSuffix(_socialController),
          ),
          Gap.h32,
        ],
      ),
    );
  }
}
