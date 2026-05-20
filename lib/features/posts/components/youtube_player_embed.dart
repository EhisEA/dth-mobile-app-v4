import "package:flutter/material.dart";
import "package:youtube_player_flutter/youtube_player_flutter.dart";

/// Inline YouTube player backed by `youtube_player_flutter`. Accepts any
/// YouTube URL shape (watch, youtu.be, embed, shorts) — the URL is normalized
/// to a video ID and handed to the controller.
class YoutubePlayerEmbed extends StatefulWidget {
  const YoutubePlayerEmbed({
    super.key,
    required this.embedUrl,
    this.radius = 12,
  });

  final String embedUrl;
  final double radius;

  @override
  State<YoutubePlayerEmbed> createState() => _YoutubePlayerEmbedState();
}

class _YoutubePlayerEmbedState extends State<YoutubePlayerEmbed> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final id =
        YoutubePlayer.convertUrlToId(widget.embedUrl) ??
        _extractYoutubeId(widget.embedUrl) ??
        widget.embedUrl;
    _controller = YoutubePlayerController(
      initialVideoId: id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: YoutubePlayer(
        controller: _controller,

        showVideoProgressIndicator: true,
        aspectRatio: 16 / 9,
      ),
    );
  }

  // Fallback ID extractor in case `YoutubePlayer.convertUrlToId` misses an
  // edge case (e.g. /shorts/ paths on older package versions).
  String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host == "youtu.be") {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    final isYouTube =
        host.endsWith("youtube.com") || host.endsWith("youtube-nocookie.com");
    if (!isYouTube) return null;
    final segs = uri.pathSegments;
    if (segs.length >= 2 && (segs[0] == "embed" || segs[0] == "shorts")) {
      return segs[1];
    }
    final v = uri.queryParameters["v"];
    if (v != null && v.isNotEmpty) return v;
    return null;
  }
}
