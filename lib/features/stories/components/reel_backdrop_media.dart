import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/stories/components/reel_player_controller.dart";
import "package:flutter/material.dart";
import "package:video_player/video_player.dart";
import "package:youtube_player_flutter/youtube_player_flutter.dart";

/// Sizes a 16:9 [player] to cover the viewport. Avoids [FittedBox] around
/// [AspectRatio] — [FittedBox] passes unbounded constraints to its child.
Widget _youtubeCoverLayout(double viewportW, double viewportH, Widget player) {
  const aspect = 16.0 / 9.0;
  if (viewportW <= 0 || viewportH <= 0) {
    return const SizedBox.shrink();
  }
  var childW = viewportW;
  var childH = viewportW / aspect;
  if (childH < viewportH) {
    childH = viewportH;
    childW = viewportH * aspect;
  }
  return ClipRect(
    child: SizedBox(
      width: viewportW,
      height: viewportH,
      child: Center(
        child: SizedBox(width: childW, height: childH, child: player),
      ),
    ),
  );
}

/// Full-bleed reel background: optional network [VideoPlayer] or YouTube embed,
/// with [posterUrl] underneath until ready / for image-only reels.
///
/// When a [controller] is provided, the active player drives its
/// `isPlaying` / `progress` state and registers a `togglePlayPause` handler
/// so the parent overlay (tap-to-pause, progress bar) stays in sync without
/// reaching into the underlying player package.
class ReelBackdropMedia extends StatefulWidget {
  const ReelBackdropMedia({
    super.key,
    required this.posterUrl,
    this.videoUrl,
    this.videoType,
    this.controller,
  });

  final String posterUrl;
  final String? videoUrl;
  final String? videoType;
  final ReelPlayerController? controller;

  @override
  State<ReelBackdropMedia> createState() => _ReelBackdropMediaState();
}

class _ReelBackdropMediaState extends State<ReelBackdropMedia> {
  VideoPlayerController? _video;
  YoutubePlayerController? _youtube;
  VoidCallback? _videoListener;
  void Function()? _youtubeListener;

  @override
  void initState() {
    super.initState();
    _initPlayback();
  }

  @override
  void didUpdateWidget(covariant ReelBackdropMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.videoType != widget.videoType) {
      _disposePlayers();
      widget.controller?.reset();
      _initPlayback();
    }
  }

  void _disposePlayers() {
    if (_video != null) {
      if (_videoListener != null) _video!.removeListener(_videoListener!);
      _video!.dispose();
    }
    _video = null;
    _videoListener = null;
    if (_youtube != null) {
      if (_youtubeListener != null) _youtube!.removeListener(_youtubeListener!);
      _youtube!.dispose();
    }
    _youtube = null;
    _youtubeListener = null;
    widget.controller?.clearToggleHandler();
    widget.controller?.clearSeekHandler();
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  bool _isYoutube(String url, String? type) {
    final t = type?.trim().toLowerCase() ?? "";
    if (t == "youtube") return true;
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? "";
    return host.contains("youtube.com") ||
        host == "youtu.be" ||
        host.contains("youtube-nocookie.com");
  }

  Future<void> _initPlayback() async {
    final raw = widget.videoUrl?.trim() ?? "";
    if (raw.isEmpty) return;
    final url = _ensureHttpScheme(raw);
    final type = widget.videoType?.trim().toLowerCase();

    if (_isYoutube(url, type)) {
      final id =
          YoutubePlayer.convertUrlToId(url) ?? _youtubeIdFromUrlFallback(url);
      if (id == null || !mounted) return;
      final yt = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: true,

          // hideControls: true,
          mute: false,
          loop: true,
          enableCaption: false,
        ),
      );
      _youtube = yt;
      _attachYoutubeListener(yt);
      widget.controller?.registerToggleHandler(_toggleYoutube);
      widget.controller?.registerSeekHandler(_seekYoutube);
      if (mounted) setState(() {});
      return;
    }

    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = c;
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.play();
      _attachVideoListener(c);
      widget.controller?.registerToggleHandler(_toggleVideo);
      widget.controller?.registerSeekHandler(_seekVideo);
      widget.controller?.updateReady(true);
      widget.controller?.updatePlaying(true);
      setState(() {});
    } catch (_) {
      await c.dispose();
      if (mounted) {
        setState(() => _video = null);
      }
    }
  }

  void _attachVideoListener(VideoPlayerController c) {
    void listener() {
      if (!mounted) return;
      final ctrl = widget.controller;
      if (ctrl == null) return;
      ctrl.updatePlaying(c.value.isPlaying);
      final total = c.value.duration.inMilliseconds;
      final pos = c.value.position.inMilliseconds;
      if (total > 0) {
        ctrl.updateProgress(pos / total);
      }
    }

    _videoListener = listener;
    c.addListener(listener);
  }

  void _attachYoutubeListener(YoutubePlayerController c) {
    void listener() {
      if (!mounted) return;
      final ctrl = widget.controller;
      if (ctrl == null) return;
      final value = c.value;
      ctrl.updateReady(value.isReady);
      ctrl.updatePlaying(value.isPlaying);
      final total = value.metaData.duration.inMilliseconds;
      final pos = value.position.inMilliseconds;
      if (total > 0) {
        ctrl.updateProgress(pos / total);
      }
    }

    _youtubeListener = listener;
    c.addListener(listener);
  }

  void _toggleVideo() {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  void _toggleYoutube() {
    final c = _youtube;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  void _seekVideo(double fraction) {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    final totalMs = c.value.duration.inMilliseconds;
    if (totalMs <= 0) return;
    c.seekTo(Duration(milliseconds: (totalMs * fraction).round()));
  }

  void _seekYoutube(double fraction) {
    final c = _youtube;
    if (c == null) return;
    final totalMs = c.value.metaData.duration.inMilliseconds;
    if (totalMs <= 0) return;
    c.seekTo(
      Duration(milliseconds: (totalMs * fraction).round()),
      allowSeekAhead: true,
    );
  }

  String _ensureHttpScheme(String url) {
    final t = url.trim();
    if (t.startsWith("//")) return "https:$t";
    if (t.startsWith("http://") || t.startsWith("https://")) return t;
    return "https://$t";
  }

  String? _youtubeIdFromUrlFallback(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host == "youtu.be" && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (host.endsWith("youtube.com")) {
      final segs = uri.pathSegments;
      if (segs.length >= 2 &&
          (segs[0] == "embed" || segs[0] == "shorts" || segs[0] == "live")) {
        return segs[1];
      }
      final v = uri.queryParameters["v"];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final poster = widget.posterUrl.trim();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (poster.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: poster,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  ColoredBox(color: AppColors.baseShimmer(context)),
              errorWidget: (context, url, error) => ColoredBox(
                color: AppColors.baseShimmer(context),
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.tint15,
                ),
              ),
            ),
          )
        else
          const ColoredBox(color: Colors.black),
        if (_video != null && _video!.value.isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _video!.value.size.width,
                height: _video!.value.size.height,
                child: VideoPlayer(_video!),
              ),
            ),
          ),
        if (_youtube != null)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mq = MediaQuery.sizeOf(context);
                final w = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : mq.width;
                final h = constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : mq.height;
                return YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _youtube!,
                    showVideoProgressIndicator: false,
                  ),
                  builder: (context, player) {
                    return _youtubeCoverLayout(w, h, player);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
