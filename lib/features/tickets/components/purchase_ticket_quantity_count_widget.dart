import "package:dth_v4/core/core.dart";
import "package:dth_v4/widgets/text/textstyles.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class PurchaseTicketCountWidget extends StatefulWidget {
  const PurchaseTicketCountWidget({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onQuantityChanged,
    this.canIncrement = true,
  });

  final int quantity;
  final int maxQuantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int> onQuantityChanged;
  final bool canIncrement;

  @override
  State<PurchaseTicketCountWidget> createState() =>
      _PurchaseTicketCountWidgetState();
}

class _PurchaseTicketCountWidgetState extends State<PurchaseTicketCountWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: "${widget.quantity}");
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(PurchaseTicketCountWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity && !_focusNode.hasFocus) {
      _controller.text = "${widget.quantity}";
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitQuantity();
    }
  }

  int _clamp(int value) {
    var next = value < 0 ? 0 : value;
    if (widget.maxQuantity > 0 && next > widget.maxQuantity) {
      next = widget.maxQuantity;
    }
    return next;
  }

  void _commitQuantity() {
    final parsed = int.tryParse(_controller.text.trim()) ?? 0;
    final next = _clamp(parsed);
    widget.onQuantityChanged(next);
    _controller.text = "$next";
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = widget.quantity > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PurchaseTicketCountButton(
          icon: Icons.remove,
          enabled: canDecrement,
          onTap: canDecrement ? widget.onDecrement : null,
          backgroundColor: canDecrement ? AppColors.black : AppColors.tint5,
          iconColor: AppColors.white,
        ),
        SizedBox(
          width: 36,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            style: AppTextStyle.semiBold.copyWith(
              fontSize: 14,
              color: AppColors.black,
            ),
            cursorColor: AppColors.primary,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _focusNode.unfocus(),
            onTapOutside: (_) => _focusNode.unfocus(),
          ),
        ),
        PurchaseTicketCountButton(
          icon: Icons.add,
          enabled: widget.canIncrement,
          onTap: widget.canIncrement ? widget.onIncrement : null,
          backgroundColor: widget.canIncrement
              ? AppColors.primary
              : AppColors.greyTint30,
          iconColor: AppColors.white,
        ),
      ],
    );
  }
}

class PurchaseTicketCountButton extends StatelessWidget {
  const PurchaseTicketCountButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
