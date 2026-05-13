import "package:flutter/foundation.dart";

/// Thin remote for whichever player [ReelBackdropMedia] is currently using
/// (direct [VideoPlayer] or `youtube_player_flutter`). The backdrop registers
/// a [_toggleHandler] when its player is ready and pushes [isPlaying] /
/// [progress] updates; outside widgets (the overlay tap-to-pause, the
/// progress indicator) drive playback via [togglePlayPause] and listen for
/// state changes via the usual `ChangeNotifier` plumbing.
///
/// Decoupling this from the backdrop keeps the surrounding UI (StoriesView,
/// FullReelBody) ignorant of which underlying player is active.
class ReelPlayerController extends ChangeNotifier {
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Normalized playback position in `[0, 1]`. Stays `0` until the player
  /// reports a non-zero duration.
  double _progress = 0;
  double get progress => _progress;

  bool _isReady = false;
  bool get isReady => _isReady;

  VoidCallback? _toggleHandler;

  /// Called by [ReelBackdropMedia] once the underlying player is initialized.
  /// Replaces any previously-registered handler so a player swap (e.g. video
  /// type change) doesn't leak the old controller.
  void registerToggleHandler(VoidCallback handler) {
    _toggleHandler = handler;
  }

  void clearToggleHandler() {
    _toggleHandler = null;
  }

  void togglePlayPause() => _toggleHandler?.call();

  void updatePlaying(bool playing) {
    if (_isPlaying == playing) return;
    _isPlaying = playing;
    notifyListeners();
  }

  void updateProgress(double value) {
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    if ((clamped - _progress).abs() < 0.001) return;
    _progress = clamped;
    notifyListeners();
  }

  void updateReady(bool ready) {
    if (_isReady == ready) return;
    _isReady = ready;
    notifyListeners();
  }

  /// Resets state when the backing media changes (new reel uid / source).
  void reset() {
    _isPlaying = false;
    _progress = 0;
    _isReady = false;
    _toggleHandler = null;
    notifyListeners();
  }
}
