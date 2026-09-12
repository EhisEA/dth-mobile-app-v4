import "dart:ui" show ImageFilter;

import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_utils/flutter_utils.dart";

Future<bool?> showMoreActionSheet(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final sheetCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return Material(
        color: Colors.transparent,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: FadeTransition(
                  opacity: animation,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          color: const Color(
                            0xff044423,
                          ).withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(sheetCurve),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      bottom: false,
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                AppText.medium(
                                  "More action",
                                  fontSize: 14,
                                  color: AppColors.tint40,
                                ),
                                const Spacer(),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: Container(
                                    height: 24,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.greyTint15,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 12,
                                      color: AppColors.greyTint55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Gap.h16,
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.greyTint20,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                24,
                                16,
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.of(dialogContext).pop(true);
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 19,
                                      backgroundColor: AppColors.redTint35,
                                      child: SvgPicture.asset(SvgAssets.delete),
                                    ),
                                    Gap.w14,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText.medium(
                                            "Delete bank account",
                                            fontSize: 15,
                                            color: AppColors.black,
                                          ),
                                          AppText.regular(
                                            "You'll need to verify this action",
                                            fontSize: 13,
                                            color: AppColors.blackTint20,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SvgPicture.asset(SvgAssets.rightArrow),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
