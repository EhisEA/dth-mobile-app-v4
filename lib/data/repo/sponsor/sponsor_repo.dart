import "package:dth_v4/data/data.dart";
import "package:flutter_utils/flutter_utils.dart";

abstract class SponsorRepo {
  Future<ApiResponse<SponsorInfo?>> getSponsor();
}
