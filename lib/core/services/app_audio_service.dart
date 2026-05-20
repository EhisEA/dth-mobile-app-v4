import "package:dth_v4/core/constants/assets.dart";
import "package:just_audio/just_audio.dart";

class AppAudioService {
  final _player = AudioPlayer();
  static AppAudioService get instance => _instance;
  static final AppAudioService _instance = AppAudioService._();

  AppAudioService._() {
    _player.setAsset(AudioAssets.screenshotSound);
    _player.playerStateStream.listen((event) async {
      if (event.processingState == ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
      }
    });
  }

  /// Plays the screenshot sound. Failures are ignored so export is never blocked.
  Future<void> playScreenshotSound() async {
    try {
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {}
  }
}
