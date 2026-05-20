import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/app_text_field.dart";
import "package:dth_v4/widgets/text/text.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class CommentComposer extends StatefulWidget {
  const CommentComposer({
    super.key,
    required this.onSubmit,
    this.replyToName,
    this.onCancelReply,
    this.submitting = false,
  });

  /// Returns true if the submission was accepted (so we can clear the field).
  final Future<bool> Function(String text) onSubmit;
  final String? replyToName;
  final VoidCallback? onCancelReply;
  final bool submitting;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;
  bool _isTextfieldFocused = false;
  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });

    _focus.addListener(() {
      setState(() {
        _isTextfieldFocused = _focus.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(covariant CommentComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyToName != null &&
        widget.replyToName != oldWidget.replyToName) {
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.submitting) return;
    final accepted = await widget.onSubmit(text);
    if (accepted && mounted) {
      _controller.clear();
      setState(() => _hasText = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final replyTo = widget.replyToName;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.tint5, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        MediaQuery.paddingOf(context).left + 16,
        8,
        16,
        (MediaQuery.paddingOf(context).bottom > 0)
            ? MediaQuery.paddingOf(context).bottom + 4
            : MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyTo != null) ...[
            Row(
              children: [
                Expanded(
                  child: AppText.regular(
                    "Replying to $replyTo",
                    fontSize: 11,
                    color: AppColors.blackTint20,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancelReply,
                  behavior: HitTestBehavior.opaque,
                  child: AppText.medium(
                    "Cancel",
                    fontSize: 11,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
            Gap.h6,
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: !widget.submitting,
                  minLines: 1,
                  maxLines: 4,
                  borderRadius: BorderRadius.circular(100),
                  fillColor: _isTextfieldFocused
                      ? AppColors.white
                      : const Color(0xffF4F4F4),
                  // textInputAction: TextInputAction.newline,
                  hint: replyTo == null
                      ? "Drop a banger..."
                      : "Write your reply...",
                  hintStyle: AppTextStyle.regular.copyWith(
                    fontSize: 13,
                    color: AppColors.blackTint20,

                    // border: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(24),
                    //   borderSide: BorderSide(color: AppColors.tint10),
                    // ),
                    // enabledBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(24),
                    //   borderSide: BorderSide(color: AppColors.tint10),
                    // ),
                    // focusedBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(24),
                    //   borderSide: BorderSide(color: AppColors.black),
                    // ),
                    // contentPadding: const EdgeInsets.symmetric(
                    //   horizontal: 16,
                    //   vertical: 10,
                    // ),
                  ),
                ),
              ),
              Gap.w8,
              GestureDetector(
                onTap: _hasText && !widget.submitting ? _submit : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasText && !widget.submitting
                        ? AppColors.primary
                        : AppColors.tint10,
                  ),
                  alignment: Alignment.center,
                  child: widget.submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : SvgPicture.asset(
                          SvgAssets.send,
                          height: 16,
                          width: 16,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
