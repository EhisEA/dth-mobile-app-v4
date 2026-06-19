import "package:dth_v4/core/core.dart";
import "package:flutter/material.dart";

class SponsorInfo {
  const SponsorInfo({
    required this.prefix,
    required this.label,
    required this.link,
    required this.color,
  });

  final String prefix;
  final String label;
  final String link;
  final String color;

  bool get isDisplayable => label.trim().isNotEmpty;

  Color get accentColor => _parseHexColor(color) ?? AppColors.primary;

  factory SponsorInfo.fromJson(Map<String, dynamic> json) {
    return SponsorInfo(
      prefix: json["prefix"]?.toString() ?? "",
      label: json["label"]?.toString() ?? "",
      link: json["link"]?.toString() ?? "",
      color: json["color"]?.toString() ?? "",
    );
  }

  static Color? _parseHexColor(String raw) {
    var hex = raw.trim();
    if (hex.isEmpty) return null;
    if (hex.startsWith("#")) hex = hex.substring(1);
    if (hex.length == 6) hex = "FF$hex";
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}
