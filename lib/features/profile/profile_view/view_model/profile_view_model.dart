import "package:dth_v4/data/data.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class ProfileViewModel extends BaseChangeNotifierViewModel {
  ProfileViewModel(this.userState);

  final UserState userState;

  ValueNotifier<UserModel?> get userModel => userState.user;
}

final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((
  ref,
) {
  return ProfileViewModel(ref.read(userProfileStateProvider));
});
