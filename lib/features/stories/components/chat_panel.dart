import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/stories/components/comment_tile.dart";
import "package:dth_v4/features/stories/view_model/reel_chat_view_model.dart";
import "package:dth_v4/widgets/dth_send_button.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class ChatPanel extends ConsumerWidget {
  const ChatPanel({
    super.key,
    required this.reelUid,
    required this.scrollController,
    required this.scrollPhysics,
    required this.bottomPad,
    required this.composerController,
  });

  final String reelUid;
  final ScrollController scrollController;
  final ScrollPhysics scrollPhysics;

  final double bottomPad;
  final TextEditingController composerController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(reelChatViewModelProvider(reelUid));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              physics: scrollPhysics,
              slivers: [
                SliverToBoxAdapter(child: Gap.h2),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            AppText.medium(
                              "Top Comments ",
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff202020),
                            ),
                            Gap.w4,
                            AppText.regular(
                              formatCount(vm.comments.length),
                              fontSize: 12,
                              color: AppColors.tint15,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            AppText.regular(
                              "Most recent",
                              fontSize: 12,
                              color: AppColors.tint25,
                            ),
                            Gap.w4,
                            SvgPicture.asset(
                              SvgAssets.downArrow,
                              width: 14,
                              height: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: Gap.h20),
                _commentsSliver(vm),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: composerController,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: composerController,
                        borderRadius: BorderRadius.circular(24),
                        hint: "Drop a banger...",
                        fillColor: const Color(0xffFAFAFA),
                        hintColor: AppColors.tint15,
                        showBorder: false,
                        enabled: !vm.submitting && reelUid.isNotEmpty,
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => SizeTransition(
                        sizeFactor: anim,
                        axis: Axis.horizontal,
                        axisAlignment: -1,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: hasText
                          ? Row(
                              key: const ValueKey("send"),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Gap.w8,
                                DthSendButton(
                                  loading: vm.submitting,
                                  onTap: () async {
                                    if (vm.submitting) return;
                                    final ok = await vm.submit(
                                      composerController.text,
                                    );
                                    if (ok) composerController.clear();
                                  },
                                ),
                              ],
                            )
                          : const SizedBox.shrink(key: ValueKey("empty")),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentsSliver(ReelChatViewModel vm) {
    if (vm.loading && vm.comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (vm.error != null && vm.comments.isEmpty) {
      return SliverToBoxAdapter(
        child: _CommentsErrorState(
          message: vm.error!.message,
          onRetry: vm.refresh,
        ),
      );
    }
    if (vm.comments.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Center(
            child: AppText.regular(
              "Be the first to drop a banger.",
              fontSize: 12,
              color: AppColors.tint15,
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      sliver: SliverList.separated(
        itemCount: vm.comments.length,
        separatorBuilder: (_, _) => Gap.h16,
        itemBuilder: (context, i) {
          final c = vm.comments[i];
          return CommentTile(
            comment: c,
            parent: false,
            onLike: () => vm.toggleCommentLike(c),
          );
        },
      ),
    );
  }
}

class _CommentsErrorState extends StatelessWidget {
  const _CommentsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          AppText.regular(
            message,
            fontSize: 12,
            color: AppColors.blackTint20,
            textAlign: TextAlign.center,
          ),
          Gap.h12,
          AppButton.primary(text: "Retry", height: 40, press: onRetry),
        ],
      ),
    );
  }
}
