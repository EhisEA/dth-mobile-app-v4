import "package:dth_v4/data/models/app_textfield_state.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_utils/flutter_utils.dart";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/text/app_text.dart";
import "package:dth_v4/widgets/text/textstyles.dart";

class AppTextField extends StatefulWidget {
  final String? hint;
  final String? title;
  final BorderRadius? borderRadius;
  final String? Function(String value)? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final List<TextInputFormatter> formatter;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final int? maxLines;
  final int? minLines;
  final Color? fillColor;
  final Color? errorColor;
  final Color? hintColor;
  final Color? titleColor;
  final Color? inActiveBorderColor;
  final Function(String)? onSubmitted;
  final int? maxLength;
  final double? height;
  late final ValueNotifier<AppTextFieldState> formState;
  final double? width;
  final FocusNode focusNode;
  final EdgeInsets? padding;
  final TextCapitalization textCapitalization;
  final EdgeInsets? contentPadding;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Widget? bottomIcon;
  final Widget? prefix;
  final bool readOnly;
  final bool showBorder;
  final TextStyle? hintStyle;
  final double? titleSize;
  final TextStyle? style;
  final void Function()? onTap;
  final TextInputAction? textInputAction;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;

  /// When true (default), tapping the field chrome requests focus. Set false
  /// for composers where the outer [GestureDetector] can refocus after Done.
  final bool tapToFocus;

  AppTextField({
    super.key,
    this.hint,
    this.title,
    this.height,
    this.borderRadius,
    this.width,
    FocusNode? focusNode,
    this.padding,
    ValueNotifier<AppTextFieldState>? formState,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.hintStyle,
    this.style,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.enabled = true,
    this.minLines,
    this.hintColor,
    this.suffixIcon,
    this.prefixIcon,
    this.bottomIcon,
    this.prefix,
    this.showBorder = true,
    this.contentPadding,
    this.isPassword = false,
    this.titleSize,
    this.readOnly = false,
    this.formatter = const [],
    this.onChanged,
    this.onSubmitted,
    this.fillColor,
    this.titleColor,
    this.errorColor,
    this.inActiveBorderColor,
    this.maxLength,
    this.textInputAction,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.tapToFocus = true,
  }) : focusNode = focusNode ?? FocusNode(),
       formState =
           formState ??
           ValueNotifier<AppTextFieldState>(AppTextFieldState.defaultValue());

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool obscure;
  late ValueNotifier<bool> hasFocus = ValueNotifier<bool>(false);
  late ValueNotifier<String?> errorState = ValueNotifier<String?>(null);

  @override
  void initState() {
    obscure = widget.isPassword;
    widget.focusNode.addListener(() {
      hasFocus.value = widget.focusNode.hasFocus;
    });
    super.initState();
  }

  void toggleVisibility() {
    setState(() {
      obscure = !obscure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: hasFocus,
      builder: (context, hasFocus, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: errorState,
          builder: (context, errorMessage, _) {
            final field = Column(
              children: [
                Container(
                  padding:
                      widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  alignment: Alignment.center,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(12),
                    color: widget.fillColor ?? AppColors.white,
                    border: Border.all(
                      color: widget.showBorder
                          ? hasFocus
                                ? (errorMessage == null
                                      ? AppColors.primary
                                      : Colors.red)
                                : (widget.inActiveBorderColor ??
                                      const Color(0xffEDEDED))
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null) ...[
                        AppText.regular(
                          widget.title!,
                          fontSize: widget.titleSize ?? 10,
                          letterSpacing: -0.2,
                          color: widget.titleColor ?? AppColors.black,
                        ),
                      ],
                      SizedBox(
                        height: widget.height,
                        child: TextFormField(
                          textCapitalization: widget.textCapitalization,
                          focusNode: widget.focusNode,
                          maxLength: widget.maxLength,
                          maxLines: widget.maxLines,
                          minLines: widget.minLines,
                          readOnly: widget.readOnly,
                          style:
                              widget.style ??
                              AppTextStyle.regular.copyWith(
                                color: AppColors.black,
                                fontSize: 14,
                              ),
                          controller: widget.controller,
                          inputFormatters: widget.formatter,
                          textInputAction: widget.textInputAction,
                          onFieldSubmitted: widget.onSubmitted,
                          validator: (value) {
                            String? error;
                            if (widget.validator != null) {
                              error = widget.validator!(value ?? '');
                            }
                            final captured = error;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              errorState.value = captured;
                            });
                            return error;
                          },
                          keyboardType: widget.keyboardType,
                          obscureText: obscure,
                          enabled: widget.enabled,
                          onChanged: widget.onChanged,
                          decoration: InputDecoration(
                            contentPadding: widget.contentPadding,
                            errorStyle: const TextStyle(fontSize: 0),
                            prefixIconConstraints: widget.prefixIconConstraints,
                            suffixIconConstraints:
                                widget.suffixIconConstraints ??
                                const BoxConstraints(maxHeight: 40),
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefix: widget.prefix,
                            prefixIcon: widget.prefixIcon,
                            suffixIcon: widget.suffixIcon,
                            isDense: true,
                            hintText: widget.hint,
                            hintStyle:
                                widget.hintStyle ??
                                AppTextStyle.regular.copyWith(
                                  color:
                                      widget.hintColor ??
                                      const Color(0xffB5B5B5),
                                  fontSize: 13,
                                  letterSpacing: -0.2,
                                ),
                            enabled: widget.enabled,
                          ),
                        ),
                      ),

                      widget.bottomIcon ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Gap.w6,
                        AppText.regular(
                          errorMessage.isEmpty
                              ? errorMessage
                              : errorMessage.capitalizeFirstLetter(),
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
              ],
            );

            if (!widget.tapToFocus && widget.onTap == null) {
              return field;
            }

            return GestureDetector(
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!();
                } else if (widget.tapToFocus) {
                  FocusScope.of(context).requestFocus(widget.focusNode);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: field,
            );
          },
        );
      },
    );
  }
}
