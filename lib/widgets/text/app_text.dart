import "package:flutter/material.dart";
import "package:dth_v4/widgets/text/textstyles.dart";

class AppText extends StatelessWidget {
  final String text;
  final bool multiText;
  final TextAlign? textAlign;
  final TextOverflow overflow;
  final Color? color;
  final Color? decorationColor;
  final bool centered;
  final int? maxLines;
  final double? fontSize;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final FontStyle? fontStyle;
  final FontWeight? fontWeight;
  final TextDecoration? decoration;
  final List<Shadow>? shadows;
  final TextStyle? baseStyle;

  /// Default: [AppTextStyle.regular].
  const AppText(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.baseStyle,
  });

  const AppText.extraLight(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.extraLight;

  const AppText.light(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.light;

  const AppText.regular(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.regular;

  const AppText.medium(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.medium;

  const AppText.semiBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.semiBold;

  const AppText.bold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.bold;

  const AppText.black(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.black;

  const AppText.matterLight(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.matterLight;

  const AppText.matterRegular(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.matterRegular;

  const AppText.matterMedium(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.matterMedium;

  const AppText.matterSemiBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.matterSemiBold;

  const AppText.matterBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.matterBold;

  const AppText.cascadiaMonoExtraLight(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.cascadiaMonoExtraLight;

  const AppText.cascadiaMonoLight(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.cascadiaMonoLight;

  const AppText.cascadiaMonoRegular(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.cascadiaMonoRegular;

  const AppText.cascadiaMonoMedium(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.cascadiaMonoMedium;

  const AppText.cascadiaMonoSemiBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.cascadiaMonoSemiBold;

  const AppText.cascadiaMonoBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.cascadiaMonoBold;

  const AppText.athleticsLight(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.athleticsLight;

  const AppText.athleticsRegular(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.athleticsRegular;

  const AppText.athleticsMedium(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.athleticsMedium;

  const AppText.athleticsBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.athleticsBold;

  const AppText.athleticsExtraBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.athleticsExtraBold;

  const AppText.athleticsBlack(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.athleticsBlack;

  const AppText.bangersRegular(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.bangersRegular;

  const AppText.shantellLight(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellLight;

  const AppText.shantellLightItalic(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellLightItalic;

  const AppText.shantellRegular(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellRegular;

  const AppText.shantellRegularItalic(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellRegularItalic;

  const AppText.shantellMedium(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellMedium;

  const AppText.shantellMediumItalic(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellMediumItalic;

  const AppText.shantellSemiBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellSemiBold;

  const AppText.shantellSemiBoldItalic(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellSemiBoldItalic;

  const AppText.shantellBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellBold;

  const AppText.shantellBoldItalic(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellBoldItalic;

  const AppText.shantellExtraBold(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellExtraBold;

  const AppText.shantellExtraBoldItalic(
    this.text, {
    super.key,
    this.multiText = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines,
    this.centered = false,
    this.shadows,
    this.textAlign,
    this.wordSpacing,
    this.decoration,
    this.decorationColor,
    this.height,
    this.letterSpacing,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  }) : baseStyle = AppTextStyle.shantellExtraBoldItalic;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (baseStyle ?? AppTextStyle.regular).copyWith(
      color: color,
      letterSpacing: letterSpacing,
      decorationColor: decorationColor,
      height: height,
      wordSpacing: wordSpacing,
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontStyle: fontStyle,
      decoration: decoration,
      shadows: shadows,
    );

    return Text(
      text,
      key: key,
      maxLines: multiText || maxLines != null ? maxLines ?? 9999999999 : 1,
      overflow: overflow,
      textAlign: centered ? TextAlign.center : textAlign ?? TextAlign.left,
      style: effectiveStyle,
    );
  }
}
