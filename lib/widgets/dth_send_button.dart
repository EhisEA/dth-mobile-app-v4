import 'package:dth_v4/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DthSendButton extends StatelessWidget {
  const DthSendButton({super.key, required this.onTap, this.loading = false});

  final VoidCallback onTap;

  /// When true, swap the send icon for a spinner and ignore taps. Used while
  /// a post / comment is in flight so the user can't double-submit.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading
            ? null
            : () {
                onTap();
                HapticFeedback.lightImpact();
              },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : SvgPicture.asset(
                  SvgAssets.send,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
        ),
      ),
    );
  }
}
