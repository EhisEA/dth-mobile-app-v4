import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:dth_v4/features/app_web_view/app_web_view.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SearchViewModel extends BaseChangeNotifierViewModel {
  SearchViewModel(this._supportRepo);

  final SupportRepo _supportRepo;

  static const String _supportSessionKey = "searchSupportSession";

  ViewModelState get supportSessionState =>
      getState(_supportSessionKey) ?? const ViewModelState.idle();

  bool get supportSessionBusy =>
      supportSessionState.maybeWhen(busy: () => true, orElse: () => false);

  Future<void> requestSupportWebSession() async {
    if (supportSessionBusy) return;

    setState(_supportSessionKey, const ViewModelState.busy());
    try {
      final res = await _supportRepo.createSupportWebSession();
      final session = res.data;
      final url = session?.url ?? "";
      if (url.isEmpty) {
        showErrorFlushbar(
          title: "Support",
          message: "Could not open support. Please try again.",
        );
        return;
      }
      await MobileNavigationService.instance.navigateTo(
        AppWebView.path,
        extra: {
          RoutingArgumentKey.title: "Support",
          RoutingArgumentKey.initialURl: url,
        },
      );
    } on ApiFailure catch (e) {
      showErrorFlushbar(title: "Support", message: e.message);
    } finally {
      setState(_supportSessionKey, const ViewModelState.idle());
    }
  }
}

final searchViewModelProvider = ChangeNotifierProvider<SearchViewModel>((ref) {
  return SearchViewModel(ref.read(supportRepositoryProvider));
});
