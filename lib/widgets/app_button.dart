import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/text/app_text.dart";

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.text,
    this.enabled = true,
    this.isLoading = false,
    this.isShort = false,
    this.onBorder = false,
    this.color,
    this.disableBGColor,
    this.disableTextColor,
    this.disableBorderColor,
    this.textColor = Colors.white,
    this.borderColor,
    this.transparent = false,
    this.press,
    this.width,
    this.borderWidth,
    this.loadingColor,
    this.height,
    this.radius,
    this.widget,
    this.image,
    this.prefixIcon,
    this.suffixIcon,
    this.fontWeight,
    this.subtitle,
    this.subtitleColor,
    this.disableSubtitleColor,
    this.subtitleFontSize,
    this.fontSize,
    this.shrinkWrap = false,
  });
  AppButton.primary({
    super.key,
    this.text,
    this.enabled = true,
    this.isShort = false,
    this.isLoading = false,
    this.onBorder = false,
    Color? disableBGColor,
    Color? disableTextColor,
    Color? disableBorderColor,
    this.borderColor = Colors.transparent,
    this.transparent = false,
    this.press,
    this.borderWidth,
    this.width,
    this.loadingColor,
    this.height,
    this.radius,
    this.widget,
    this.prefixIcon,
    this.suffixIcon,
    this.image,
    this.fontWeight,
    this.subtitle,
    this.subtitleColor,
    this.disableSubtitleColor,
    this.subtitleFontSize,
    this.fontSize,
    this.shrinkWrap = false,
  }) : color = AppColors.primary,
       disableBorderColor = disableBorderColor ?? const Color(0xFFDBDBDB),
       disableBGColor =
           disableBGColor ?? AppColors.primary.withValues(alpha: .1),
       disableTextColor = disableTextColor ?? const Color(0xFFDBDBDB),
       textColor = AppColors.white;

  AppButton.secondary({
    super.key,
    this.text,
    this.enabled = true,
    this.isShort = false,
    this.isLoading = false,
    this.onBorder = false,
    Color? disableBGColor,
    Color? disableTextColor,
    Color? disableBorderColor,
    this.borderColor = Colors.transparent,
    this.transparent = false,
    this.press,
    this.width,
    this.borderWidth,
    this.height,
    this.radius,
    this.loadingColor,
    this.widget,
    this.color = const Color(0xFFF3F4F7),
    this.prefixIcon,
    this.suffixIcon,
    this.image,
    this.fontWeight,
    this.subtitle,
    this.subtitleColor,
    this.disableSubtitleColor,
    this.subtitleFontSize,
    this.fontSize,
    this.shrinkWrap = false,
  }) : // color = AppColors.primaryColor .withValues(alpha:0.25),
       disableBorderColor = disableBorderColor ?? const Color(0xFFDBDBDB),
       disableBGColor =
           disableBGColor ?? AppColors.primary.withValues(alpha: .1),
       disableTextColor =
           disableTextColor ?? AppColors.primary.withValues(alpha: .3),
       textColor = AppColors.primary;

  const AppButton.onBorder({
    super.key,
    this.text,
    this.enabled = true,
    this.isLoading = false,
    this.isShort = false,
    this.onBorder = true,
    this.color = Colors.transparent,
    // this.textColor = AppColors.primary,
    // this.borderColor = AppColors.primary,
    this.transparent = false,
    this.disableBGColor,
    this.disableTextColor,
    this.disableBorderColor,
    this.press,
    this.loadingColor,
    this.width,
    this.height,
    this.borderWidth,
    this.radius,
    this.widget,
    this.prefixIcon,
    this.suffixIcon,
    this.fontWeight,
    this.image,
    this.borderColor = AppColors.primary,
    this.textColor = AppColors.primary,
    this.subtitle,
    this.subtitleColor,
    this.disableSubtitleColor,
    this.subtitleFontSize,
    this.fontSize,
    this.shrinkWrap = false,
  });
  //  borderColor = AppColors.primary;

  final String? text;
  final String? image;
  final VoidCallback? press;
  final bool enabled;
  final bool isLoading;
  final bool isShort;
  final Color? color;
  final Color? textColor;
  final Color? disableBGColor;
  final Color? disableTextColor;
  final bool transparent;
  final double? borderWidth;
  final double? width;
  final double? height;
  final double? radius;
  final bool? onBorder;
  final Color? borderColor;
  final Color? loadingColor;
  final Color? disableBorderColor;
  final Widget? widget;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FontWeight? fontWeight;
  final String? subtitle;
  final Color? subtitleColor;
  final Color? disableSubtitleColor;
  final double? subtitleFontSize;
  final double? fontSize;

  /// When true, horizontal size follows label (plus icons); [width] may stay null.
  final bool shrinkWrap;

  Widget _buildLabel() {
    final title = AppText.regular(
      text ?? "",
      fontSize: fontSize ?? (isShort ? 16 : 12),
      fontWeight: fontWeight ?? FontWeight.w400,
      color: enabled ? textColor : disableTextColor ?? AppColors.tint15,
      centered: true,
    );

    final sub = subtitle;
    if (sub == null || sub.isEmpty) {
      return title;
    }

    final baseTitle = textColor ?? Colors.white;
    final subEnabled = subtitleColor ?? baseTitle;
    final subDisabled =
        disableSubtitleColor ??
        (disableTextColor ?? AppColors.white).withValues(alpha: 0.72);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        title,
        AppText.regular(
          sub,
          fontSize: subtitleFontSize ?? 10,
          fontWeight: FontWeight.w400,
          height: 0,
          color: enabled ? subEnabled : subDisabled,
          centered: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep normal button chrome while loading (callers often set enabled: false).
    final showEnabledChrome = enabled || isLoading;
    final looseWidth = transparent || shrinkWrap;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: width ?? (looseWidth ? null : double.infinity),
      height: height ?? (transparent ? null : (52)),
      decoration: BoxDecoration(
        image: image != null
            ? DecorationImage(
                image: AssetImage(image!),
                fit: BoxFit.fill,
                colorFilter: showEnabledChrome
                    ? null
                    : ColorFilter.mode(Colors.grey, BlendMode.srcIn),
              )
            : null,
        border: Border.all(
          width: borderWidth ?? 1,
          color: onBorder!
              ? showEnabledChrome
                    ? borderColor ?? AppColors.white.withValues(alpha: 0.4)
                    : disableBorderColor ?? Colors.transparent
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(radius ?? 100),
        color: transparent
            ? Theme.of(context).scaffoldBackgroundColor
            : showEnabledChrome
            ? color ?? AppColors.primary
            : disableBGColor ?? const Color(0xffF2F4F7),
      ),
      child: TextButton(
        style: (isLoading || shrinkWrap)
            ? TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: isLoading && shrinkWrap
                    ? const EdgeInsets.symmetric(horizontal: 20)
                    : isLoading
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 20),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null,
        onPressed: () {
          enabled && !isLoading ? press?.call() : null;
          HapticFeedback.lightImpact();
        },
        child: isLoading
            ? shrinkWrap
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color?>(
                              loadingColor ?? textColor,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color?>(
                            loadingColor ?? textColor,
                          ),
                        ),
                      ),
                    )
            : Row(
                mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  if (prefixIcon != null) ...[prefixIcon!, Gap.w8],
                  if (shrinkWrap)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: widget ?? _buildLabel(),
                    )
                  else
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: widget ?? _buildLabel(),
                        ),
                      ),
                    ),
                  if (suffixIcon != null) ...[Gap.w8, suffixIcon!],
                ],
              ),
      ),
    );
  }
}
