import "dart:async";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/search/components/search_header.dart";
import "package:dth_v4/features/search/components/search_trending_reels.dart";
import "package:dth_v4/features/support/support.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  static const String path = NavigatorRoutes.search;

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late final FocusNode _searchFocus;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(supportSessionViewModelProvider);
    return Loader.page(
      isLoading: vm.supportSessionBusy,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gap.h10,
                  SearchHeader(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onSupportTap: () => unawaited(
                      ref
                          .read(supportSessionViewModelProvider)
                          .requestSupportWebSession(),
                    ),
                  ),
                  Gap.h16,
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 100),
                      children: [
                        SearchTrendingReels(),
                        Gap.h24,
                        // AppText.medium(
                        //   "Upcoming Shows",
                        //   color: AppColors.black,
                        //   fontSize: 12,
                        // ),
                        // Gap.h12,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
