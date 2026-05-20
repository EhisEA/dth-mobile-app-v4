import 'package:dth_v4/core/core.dart';
import 'package:flutter/material.dart';

class AvatarDot extends StatelessWidget {
  const AvatarDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: ClipOval(child: Image.asset(ImageAssets.user1, fit: BoxFit.cover)),
    );
  }
}
