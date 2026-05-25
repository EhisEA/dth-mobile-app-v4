import "package:dth_v4/core/constants/assets.dart";
import "package:dth_v4/core/router/router.dart";
import "package:dth_v4/core/utils/colors.dart";
import "package:dth_v4/core/utils/format_count.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/posts/components/like_chip.dart";
import "package:dth_v4/features/posts/models/post_mapper.dart"
    show formatTimeAgo;
import "package:dth_v4/features/stories/components/chat_split_body.dart";
import "package:dth_v4/features/stories/components/full_reel_body.dart";
import "package:dth_v4/features/stories/components/reel_backdrop_media.dart";
import "package:dth_v4/features/stories/components/reel_player_controller.dart";
import "package:dth_v4/features/stories/view_model/reel_chat_view_model.dart";
import "package:dth_v4/features/stories/view_model/reels_cache.dart";
import "package:dth_v4/widgets/dth_send_button.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

/// Reel viewer. Takes only [reelUid] — every other field (title, description,
/// poster, video, like state, counts) is hydrated from [ReelsCache] (warm from
/// the listing screens) and refreshed by [ReelChatViewModel.fetchReel].
class StoriesView extends ConsumerStatefulWidget {
  const StoriesView({super.key, required this.reelUid});

  final String reelUid;

  static const String path = NavigatorRoutes.stories;

  @override
  ConsumerState<StoriesView> createState() => _StoriesViewState();
}

class _StoriesViewState extends ConsumerState<StoriesView> {
  bool _chatOpen = false;
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  final ReelPlayerController _playerController = ReelPlayerController();

  /// Single GlobalKey for the reel backdrop — lets Flutter reparent the same
  /// State (and its underlying VideoPlayer / YoutubePlayer) when chat opens
  /// and the layout flips, so playback doesn't restart at zero.
  final GlobalKey _backdropKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.reelUid.isNotEmpty) {
      // Force VM creation so the reel-detail fetch kicks off before the first
      // frame — Riverpod creates the family member on first read.
      ref.read(reelChatViewModelProvider(widget.reelUid));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Same idea as post detail on dark media: light status bar icons.
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _composerController.dispose();
    _composerFocus.dispose();
    _playerController.dispose();
    super.dispose();
  }

  void _onReelTap() {
    FocusScope.of(context).unfocus();
    if (_chatOpen) {
      setState(() => _chatOpen = false);
      return;
    }
    _playerController.togglePlayPause();
  }

  void _toggleChat() {
    setState(() => _chatOpen = !_chatOpen);
    HapticFeedback.lightImpact();
  }

  void _onBack() {
    if (_chatOpen) {
      setState(() => _chatOpen = false);
    } else {
      MobileNavigationService.instance.goBack();
    }
  }

  /// Pull-to-dismiss when the chat sheet is already at its minimum height.
  void _closeChatFromDrag() {
    if (!_chatOpen) return;
    setState(() => _chatOpen = false);
    HapticFeedback.lightImpact();
  }

  Future<void> _toggleLike() async {
    if (widget.reelUid.isEmpty) return;
    await ref.read(reelChatViewModelProvider(widget.reelUid)).toggleReelLike();
  }

  Future<void> _submitFromReel() async {
    if (widget.reelUid.isEmpty) return;
    final vm = ref.read(reelChatViewModelProvider(widget.reelUid));
    if (vm.submitting) return;
    final ok = await vm.submit(_composerController.text);
    if (!mounted) return;
    if (ok) {
      _composerController.clear();
      _composerFocus.unfocus();
    }
  }

  /// Resolves the reel's playable URL + type from the API payload. Prefers
  /// `video_link` (YouTube / embed), falls back to a direct file in `media`.
  ({String? url, String? type}) _resolveVideo(TimelineReel reel) {
    final link = reel.videoLink?.trim();
    if (link != null && link.isNotEmpty) {
      return (url: link, type: reel.videoType ?? "youtube");
    }
    final media = reel.media;
    final mediaUrl = media?.url?.trim();
    final mime = media?.mimeType?.trim().toLowerCase() ?? "";
    if (mediaUrl != null && mediaUrl.isNotEmpty && mime.startsWith("video/")) {
      return (url: mediaUrl, type: "file");
    }
    return (url: null, type: null);
  }

  String _resolvePoster(TimelineReel reel) {
    final thumb = reel.media?.thumbnail?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final videoThumb = reel.videoThumbnail?.trim();
    if (videoThumb != null && videoThumb.isNotEmpty) return videoThumb;
    return reel.media?.url?.trim() ?? "";
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    // Watch the cache (not the VM) for the reel itself — keeps StoriesView in
    // sync with home/search if either screen mutates the reel out from under
    // us. The VM still owns fetching + writing through this same cache.
    final reel = ref.watch(
      reelsCacheProvider.select((c) => c.get(widget.reelUid)),
    );
    final vmLoading = ref.watch(
      reelChatViewModelProvider(widget.reelUid).select((v) => v.loading),
    );
    final vmSubmitting = ref.watch(
      reelChatViewModelProvider(widget.reelUid).select((v) => v.submitting),
    );

    if (reel == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: vmLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const AppText.regular("No media", color: Colors.white),
        ),
      );
    }

    final poster = _resolvePoster(reel);
    final (url: videoUrl, type: videoType) = _resolveVideo(reel);
    final liked = reel.viewerReacted;
    final likeCount = reel.counts.reactions;

    // Build the backdrop once with a stable GlobalKey, then hand it to
    // whichever layout owns the reel cell. Reparenting via GlobalKey keeps
    // the player instance alive across the chat open/close flip.
    final backdrop = ReelBackdropMedia(
      key: _backdropKey,
      posterUrl: poster,
      videoUrl: videoUrl,
      videoType: videoType,
      controller: _playerController,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (!_chatOpen) Positioned.fill(child: backdrop),
            if (_chatOpen)
              ChatSplitBody(
                reelUid: widget.reelUid,
                topPad: topPad,
                bottomPad: bottomPad,
                composerController: _composerController,
                onBack: _onBack,
                onCloseChat: _closeChatFromDrag,
                playerController: _playerController,
                backdrop: backdrop,
                initialSheetFraction: 0.3,
              )
            else
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onReelTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _playerController,
                        builder: (context, _) => FullReelBody(
                          imageUrl: poster,
                          videoUrl: videoUrl,
                          videoType: videoType,
                          topPad: topPad,
                          bottomPad: bottomPad,
                          onBack: _onBack,
                          onChatTap: _toggleChat,
                          description: reel.description,
                          timeAgo: formatTimeAgo(reel.createdAt),
                          progress: _playerController.progress,
                          isPlaying: _playerController.isPlaying,
                          hasVideo: videoUrl != null && videoUrl.isNotEmpty,
                          onSeekStart: _playerController.startScrub,
                          onSeek: _playerController.scrubTo,
                          onSeekEnd: _playerController.endScrub,
                          excludeBackdrop: true,
                        ),
                      ),
                    ),

                    Container(
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: bottomPad + 16,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(color: AppColors.mainBlack),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _composerController,
                        builder: (context, value, _) {
                          final hasText = value.text.trim().isNotEmpty;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _composerController,
                                  focusNode: _composerFocus,
                                  tapToFocus: false,
                                  fillColor: const Color(
                                    0xffEFEFEF,
                                  ).withValues(alpha: 0.16),
                                  showBorder: false,
                                  borderRadius: BorderRadius.circular(24),
                                  hint: "Join the vibe...",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  minLines: 1,
                                  maxLines: 5,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _composerFocus.unfocus(),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, anim) =>
                                    SizeTransition(
                                      sizeFactor: anim,
                                      axis: Axis.horizontal,
                                      axisAlignment: -1,
                                      child: FadeTransition(
                                        opacity: anim,
                                        child: child,
                                      ),
                                    ),
                                child: hasText
                                    ? Row(
                                        key: const ValueKey("send"),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Gap.w8,
                                          DthSendButton(
                                            loading: vmSubmitting,
                                            onTap: _submitFromReel,
                                          ),
                                        ],
                                      )
                                    : Row(
                                        key: const ValueKey("actions"),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Gap.w8,
                                          LikeChip(
                                            liked: liked,
                                            count: likeCount,
                                            countLabel: formatCount(likeCount),
                                            onTap: _toggleLike,
                                            iconSize: 24,
                                            fontSize: 14,
                                            inactiveColor: AppColors.white,
                                            countColor: AppColors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                          ),
                                          _ReelComposerIcon(
                                            onTap: _toggleChat,
                                            child: SvgPicture.asset(
                                              SvgAssets.messagesBorder,
                                              height: 24,
                                              width: 24,
                                              colorFilter: ColorFilter.mode(
                                                AppColors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          _ReelComposerIcon(
                                            onTap: () =>
                                                HapticFeedback.lightImpact(),
                                            child: SvgPicture.asset(
                                              SvgAssets.share,
                                              height: 24,
                                              width: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReelComposerIcon extends StatelessWidget {
  const _ReelComposerIcon({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: SizedBox(
          width: kMinInteractiveDimension,
          height: kMinInteractiveDimension,
          child: Center(child: child),
        ),
      ),
    );
  }
}
