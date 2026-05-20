import "dart:async";
import "package:dth_v4/core/core.dart";
import "package:dth_v4/data/data.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_utils/flutter_utils.dart";

class UserProfileState extends BaseState {
  final LocalCache _localCache;
  final AuthRepo _authRepository;

  UserProfileState(this._localCache, this._authRepository);

  final _logger = const AppLogger(UserProfileState);
  final Debouncer _debouncer = Debouncer(milliseconds: 60000);

  late final ValueNotifier<UserModel?> _user = ValueNotifier(null);
  ValueNotifier<UserModel?> get user => _user;

  void setUser(UserModel? newUser) {
    _user.value = newUser;
  }

  void init() {
    unawaited(getUserDetails());
    _debouncer.cancel();
    _debouncer.runPeriodic(() => updateUserDataFromServer());
  }

  Future<void> getUserDetails() async {
    try {
      final userData = _localCache.getUserData();
      final hasToken = _localCache.getToken() != null;

      // When signed in, prefer the server first. Applying stale cache before the
      // GET completes can overwrite a fresh user right after profile PUT (race).
      if (hasToken) {
        await getUserDetailsFromServer();
        if (_user.value == null && userData != null) {
          _user.value = UserModel.fromJson(userData);
          _logger.i(
            "getUserDetails: fallback _user from cache (server had no user): "
            "${_user.value?.toJson()}",
          );
        }
        return;
      }

      if (userData != null) {
        _user.value = UserModel.fromJson(userData);
        _logger.i(
          "getUserDetails: set _user from local cache (no token): "
          "${_user.value?.toJson()}",
        );
      }
    } catch (e) {
      handleError(e, "getUserDetails");
    }
  }

  Future<void> updateUserDataFromServer() async {
    if (_user.value == null) {
      _debouncer.cancel();
      return;
    }

    await getUserDetailsFromServer();
  }

  Future<void> getUserDetailsFromServer() async {
    try {
      final response = await _authRepository.getUserData();
      _logger.i(
        "getUserDetailsFromServer: server response: ${response.data?.toJson()}",
      );

      if (response.data == null) return;
      _user.value = response.data!;
      _logger.i(
        "getUserDetailsFromServer: set _user to server data: ${_user.value?.toJson()}",
      );
      await _localCache.saveUserData(response.data!.toJson());
    } catch (e) {
      if (e is ApiFailure &&
          (e.statusCode == 401 ||
              e.message.toLowerCase().contains("unauthenticated"))) {
        await _authRepository.clearLocalAuthSession();
        logOut();
        return;
      }
      handleError(e, "getUserDetails");
    }
  }

  /// Persists [user], updates in-memory state, then reconciles with the server.
  /// Use after profile mutations so tabs (e.g. Profile) stay in sync with `/me`.
  Future<void> updateUserData(UserModel user) async {
    await _localCache.saveUserData(user.toJson());
    _user.value = user;
    await getUserDetailsFromServer();
  }

  void logOut() {
    _debouncer.cancel();
    _user.value = null;
  }

  /// Server revoke (best effort), local cache clear, and in-memory user reset.
  Future<void> signOut() async {
    await _authRepository.logout();
    logOut();
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _user.dispose();
  }
}

/// Backward-compatible alias so existing `UserState` references still compile.
typedef UserState = UserProfileState;

final userProfileStateProvider = Provider((ref) {
  final state = UserProfileState(
    ref.read(localCacheProvider),
    ref.read(authRepositoryProvider),
  );
  ref.onDispose(state.dispose);
  return state;
});

/// Backward-compatible alias so existing `userStateProvider` references still compile.
final userStateProvider = userProfileStateProvider;
