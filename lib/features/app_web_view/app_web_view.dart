import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:webview_flutter/webview_flutter.dart";

class AppWebView extends ConsumerStatefulWidget {
  static const String path = NavigatorRoutes.webView;
  const AppWebView({
    super.key,
    required this.initialURl,
    required this.title,
    this.callbackUrl,
  });

  final String? callbackUrl;
  final String initialURl;
  final String title;

  @override
  ConsumerState<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends ConsumerState<AppWebView> {
  late final WebViewController controller;
  int progress = 0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // On web, open the URL directly in the browser
      LinkLauncher.openURL(widget.initialURl);
      return;
    }
    String url = widget.initialURl;
    if (widget.initialURl.toLowerCase().contains(".pdf")) {
      url = "https://docs.google.com/gview?=true&url=${widget.initialURl}";
    }

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                this.progress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            final cb = widget.callbackUrl;
            if (cb != null && cb.isNotEmpty && url.contains(cb)) {
              Navigator.pop<bool>(context, true);
            }
          },
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        appBar: DthAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: widget.title,
          actions: [
            GestureDetector(
              onTap: () {
                LinkLauncher.openURL(widget.initialURl);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Icon(Icons.launch, color: AppColors.black, size: 18),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (progress != 100)
              LinearProgressIndicator(
                value: progress.toDouble() / 100,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              ),
            Expanded(child: WebViewWidget(controller: controller)),
          ],
        ),
      ),
    );
  }
}
