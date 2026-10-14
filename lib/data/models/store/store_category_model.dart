import "package:flutter/foundation.dart";

@immutable
class StoreCategoryDto {
  const StoreCategoryDto({required this.uid, required this.name});

  final String uid;
  final String name;

  factory StoreCategoryDto.fromJson(Map<String, dynamic> json) {
    return StoreCategoryDto(
      uid: (json["uid"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
    );
  }
}
