import "package:cached_network_image/cached_network_image.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/features/stories/models/story.dart";
import "package:dth_v4/widgets/widgets.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:flutter_utils/flutter_utils.dart";

class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key, required this.stories, this.onStoryTap});

  final List<Story> stories;
  final void Function(Story story)? onStoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 157,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => Gap.w8,
        itemBuilder: (context, index) {
          final s = stories[index];
          return GestureDetector(
            onTap: () => onStoryTap?.call(s),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 104,
              child: Container(
                width: 104,
                height: 157,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: s.imageUrl,
                      height: 157,
                      width: 104,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: AppColors.baseShimmer(context),
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.tint15,
                        ),
                      ),
                      placeholder: (_, ___) =>
                          ColoredBox(color: AppColors.baseShimmer(context)),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xff121212).withValues(alpha: 0.0),
                              const Color(0xff121212),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      left: 12,
                      child: AppText.semiBold(
                        s.label,
                        fontSize: 10,
                        maxLines: 2,
                        color: AppColors.white,
                        height: 1.2,
                        // centered: true,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: SvgPicture.asset(SvgAssets.homeStar),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
