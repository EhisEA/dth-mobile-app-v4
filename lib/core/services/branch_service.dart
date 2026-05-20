import "dart:async";

import "package:dth_v4/core/constants/deep_linking_keys.dart";
import "package:dth_v4/core/services/deep_link_service.dart";
import "package:flutter_branch_sdk/flutter_branch_sdk.dart";
import "package:flutter_utils/flutter_utils.dart";

class BranchService implements DeepLinkSource {
  BranchService._();
  static final BranchService instance = BranchService._();

  static const _logger = AppLogger(BranchService);

  StreamSubscription<Map<dynamic, dynamic>>? _sub;
  final _controller = StreamController<DeepLink>.broadcast();

  @override
  Stream<DeepLink> get links => _controller.stream;

  @override
  Future<void> initialise({bool enableLogging = false}) async {
    await FlutterBranchSdk.init(enableLogging: enableLogging);

    _sub = FlutterBranchSdk.listSession().listen(
      _handleSession,
      onError: (Object err) => _logger.e("Branch listSession error: $err"),
    );
  }

  void _handleSession(Map<dynamic, dynamic> data) {
    if (data[BranchSessionKey.clickedBranchLink] != true) return;
    _controller.add(
      DeepLink(
        path: data[BranchSessionKey.deepLinkPath] as String?,
        data: data,
      ),
    );
  }

  @override
  Future<String?> createLink({
    required String canonicalIdentifier,
    required String feature,
    required String path,
    String channel = DeepLinkChannel.app,
    String campaign = "",
    String title = "",
    String description = "",
    String imageUrl = "",
    Map<String, dynamic> data = const {},
  }) async {
    final metadata = BranchContentMetaData();
    data.forEach(metadata.addCustomMetadata);

    final buo = BranchUniversalObject(
      canonicalIdentifier: canonicalIdentifier,
      title: title,
      contentDescription: description,
      imageUrl: imageUrl,
      contentMetadata: metadata,
    );

    final linkProperties = BranchLinkProperties(
      channel: channel,
      feature: feature,
      campaign: campaign,
    )..addControlParam(BranchControlParam.deeplinkPath, path);

    final response = await FlutterBranchSdk.getShortUrl(
      buo: buo,
      linkProperties: linkProperties,
    );

    if (!response.success) {
      _logger.e(
        "Branch getShortUrl failed: ${response.errorCode} ${response.errorMessage}",
      );
      return null;
    }
    return response.result as String?;
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _controller.close();
  }
}
