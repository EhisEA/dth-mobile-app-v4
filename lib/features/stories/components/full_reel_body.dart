import "package:dth_v4/features/stories/components/reel_backdrop_media.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/tickets/tickets.dart";
import "package:dth_v4/widgets/text/text.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class FullReelBody extends StatefulWidget {
  const FullReelBody({
    super.key,
    required this.imageUrl,
    this.videoUrl,
    this.videoType,
    required this.topPad,
    required this.bottomPad,
    required this.onBack,
    required this.onChatTap,
    required this.description,
    required this.timeAgo,
    this.progress = 0,
    this.isPlaying = false,
    this.hasVideo = false,
    this.onSeekStart,
    this.onSeek,
    this.onSeekEnd,

    /// When true, skip [ReelBackdropMedia] — parent already paints the reel.
    this.excludeBackdrop = false,
  });

  final String imageUrl;
  final String? videoUrl;
  final String? videoType;
  final double topPad;
  final double bottomPad;
  final VoidCallback onBack;
  final VoidCallback onChatTap;
  final String description;
  final String timeAgo;
  final bool excludeBackdrop;

  /// Normalized 0..1 playback position. Drives the bottom progress bar.
  final double progress;
  final bool isPlaying;
  final bool hasVideo;

  /// Seek-bar gesture callbacks. [onSeek] receives a normalized 0..1 target.
  /// [onSeekStart] / [onSeekEnd] bracket a drag so the parent can suppress
  /// player-side progress updates while the user is dragging.
  final VoidCallback? onSeekStart;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onSeekEnd;

  /// Caption character budget for the truncated state; "Read more" appears
  /// only when [description] exceeds this length.
  static const int _previewMaxChars = 92;

  @override
  State<FullReelBody> createState() => _FullReelBodyState();
}

class _FullReelBodyState extends State<FullReelBody> {
  bool _expanded = false;
  late final TapGestureRecognizer _toggleTap;

  @override
  void initState() {
    super.initState();
    _toggleTap = TapGestureRecognizer()..onTap = _toggleExpanded;
  }

  @override
  void dispose() {
    _toggleTap.dispose();
    super.dispose();
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  String _captionPreview(String body, {int maxChars = 96}) {
    final s = body.trim();
    if (s.length <= maxChars) return s;
    return "${s.substring(0, maxChars).trimRight()}...";
  }

  Widget _whiteSvg(String asset, {double size = 28}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.description.trim();
    final isLong = body.length > FullReelBody._previewMaxChars;
    final showFull = _expanded || !isLong;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!widget.excludeBackdrop)
          Positioned.fill(
            child: ReelBackdropMedia(
              posterUrl: widget.imageUrl,
              videoUrl: widget.videoUrl,
              videoType: widget.videoType,
            ),
          ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.mainBlack.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: widget.topPad + 8,
          left: 12,
          child: CircleBlurIconButton(
            onTap: widget.onBack,
            child: _whiteSvg(SvgAssets.backArrow, size: 20),
          ),
        ),

        // Positioned(
        //   top: widget.topPad + 8,
        //   right: 12,
        //   child: CircleBlurIconButton(
        //     onTap: widget.onChatTap,
        //     child: _whiteSvg(SvgAssets.messagesBorder, size: 20),
        //   ),
        // ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(SvgAssets.primaryLogo),
                    Gap.w10,
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                  SvgAssets.blackLogo,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                Gap.w4,
                                AppText.regular(
                                  "with",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.tint5,
                                ),
                                Gap.w4,
                                AppText.regular(
                                  "Contestant Publicity",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xffFCFCFC),
                                ),
                                if (widget.timeAgo.isNotEmpty) ...[
                                  Gap.w8,
                                  AppText.regular(
                                    widget.timeAgo,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.tint5,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Gap.h4,
                          if (body.isNotEmpty)
                            Text.rich(
                              TextSpan(
                                style: AppTextStyle.regular.copyWith(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                                children: [
                                  TextSpan(
                                    text: showFull
                                        ? body
                                        : _captionPreview(
                                            body,
                                            maxChars:
                                                FullReelBody._previewMaxChars,
                                          ),
                                  ),
                                  if (isLong)
                                    TextSpan(
                                      text: _expanded
                                          ? " Show less"
                                          : " Read more",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: _toggleTap,
                                    ),
                                ],
                              ),
                              maxLines: showFull ? null : 2,
                              overflow: showFull
                                  ? TextOverflow.clip
                                  : TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.hasVideo) ...[Gap.h12],
              if (widget.hasVideo) ...[
                Gap.h16,
                _ReelSeekBar(
                  progress: widget.progress,
                  onSeekStart: widget.onSeekStart,
                  onSeek: widget.onSeek,
                  onSeekEnd: widget.onSeekEnd,
                ),
                Gap.h8,
              ],
            ],
          ),
        ),
        // Centered play icon: shown when paused (video reels) or when the
        // reel is image-only (no playback to start). Tap-to-toggle is wired
        // by the parent so a single GestureDetector handles the whole reel.
        // if (!widget.hasVideo || !widget.isPlaying)
        //   IgnorePointer(
        //     child: Center(
        //       child: ClipOval(
        //         child: BackdropFilter(
        //           filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        //           child: Container(
        //             width: 64,
        //             height: 64,
        //             alignment: Alignment.center,
        //             color: Colors.black.withValues(alpha: 0.40),
        //             child: SvgPicture.asset(
        //               SvgAssets.play,
        //               width: 28,
        //               height: 28,
        //               colorFilter: const ColorFilter.mode(
        //                 Colors.white,
        //                 BlendMode.srcIn,
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}

/// Draggable seek bar. Renders a thin progress line but exposes a taller
/// transparent hit area so the user can grab it with a finger; horizontal
/// drags and taps map to a normalized 0..1 target and are reported to the
/// parent (which seeks the underlying player via [ReelPlayerController]).
class _ReelSeekBar extends StatelessWidget {
  const _ReelSeekBar({
    required this.progress,
    this.onSeekStart,
    this.onSeek,
    this.onSeekEnd,
  });

  final double progress;
  final VoidCallback? onSeekStart;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onSeekEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void emit(double dx) {
          if (width <= 0) return;
          onSeek?.call((dx / width).clamp(0.0, 1.0));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            onSeekStart?.call();
            emit(d.localPosition.dx);
          },
          onTapUp: (_) => onSeekEnd?.call(),
          onTapCancel: () => onSeekEnd?.call(),
          onHorizontalDragStart: (d) {
            onSeekStart?.call();
            emit(d.localPosition.dx);
          },
          onHorizontalDragUpdate: (d) => emit(d.localPosition.dx),
          onHorizontalDragEnd: (_) => onSeekEnd?.call(),
          onHorizontalDragCancel: () => onSeekEnd?.call(),
          // Tall transparent hit zone (~44 logical px, matches Apple/Google
          // minimum touch target) with the visible 2px bar pinned to the
          // bottom. The full height of the SizedBox catches taps and drags
          // so users get a generous scrub area without making the bar
          // visually thicker.
          child: SizedBox(
            height: 4,
            child: Align(
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: AppColors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
