import "package:dth_v4/data/models/support_web_session.dart";
import "package:flutter_utils/flutter_utils.dart";

abstract class SupportRepo {
  Future<ApiResponse<SupportWebSession>> createSupportWebSession();
}
