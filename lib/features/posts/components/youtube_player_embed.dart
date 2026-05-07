import "dart:io" show Platform;

import "package:flutter/material.dart";
import "package:webview_flutter/webview_flutter.dart";

/// Inline YouTube player that loads the embed URL inside a WebView with
/// autoplay enabled. Expects an embed-style URL like
/// `https://www.youtube.com/embed/VIDEO_ID` (which is what the API returns).
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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      // Default WebView UA on Android contains "; wv)" which YouTube's embed
      // checks treat as untrusted (Error 153). Spoofing a real Chrome / Safari
      // Mobile UA also avoids the iOS default UA, which is minimal enough that
      // YouTube sometimes refuses inline playback.
      ..setUserAgent(_browserUserAgent())
      ..loadHtmlString(_buildIframeHtml(widget.embedUrl));
  }

  String _browserUserAgent() {
    if (Platform.isIOS) {
      return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) "
          "AppleWebKit/605.1.15 (KHTML, like Gecko) "
          "Version/17.4 Mobile/15E148 Safari/604.1";
    }
    return "Mozilla/5.0 (Linux; Android 14) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Mobile Safari/537.36";
  }

  /// YouTube's `/embed/` page must be loaded inside an iframe — otherwise the
  /// IFrame API can't establish its parent-origin handshake and the player
  /// shows "Error 153 / Video player configuration error" for any video with
  /// even mild embedding restrictions. Wrapping the embed in our own HTML
  /// document and pointing an iframe at it satisfies that contract. The
  /// `allow="autoplay"` attribute is the modern (Permissions Policy) way to
  /// grant inline autoplay; `mute=1` is still required because iOS blocks
  /// unmuted autoplay without a user gesture.
  String _buildIframeHtml(String embedUrl) {
    final src = _withPlaybackParams(embedUrl).toString();
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
  html, body { margin: 0; padding: 0; background: #000; height: 100%; overflow: hidden; }
  .frame { position: absolute; inset: 0; }
  iframe { width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<div class="frame">
  <iframe src="$src"
    allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
    allowfullscreen></iframe>
</div>
</body>
</html>
''';
  }

  Uri _withPlaybackParams(String embedUrl) {
    var base = Uri.parse(embedUrl);
    // Privacy-enhanced no-cookie host. Has more permissive embed rules than
    // www.youtube.com — fixes "Error 153 / video player configuration error"
    // for many videos that the standard /embed/ host refuses to play in a
    // WebView context.
    if (base.host == "www.youtube.com" || base.host == "youtube.com") {
      base = base.replace(host: "www.youtube-nocookie.com");
    }
    final params = Map<String, String>.from(base.queryParameters);
    params["autoplay"] = "1";
    params["playsinline"] = "1";
    params["rel"] = "0";
    params["mute"] = "1";
    return base.replace(queryParameters: params);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
