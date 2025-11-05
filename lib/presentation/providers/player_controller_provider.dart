import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_music_test_app/core/di/providers.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';

final playerControllerProvider = Provider<PlayerController>((ref) {
  return PlayerController(ref);
});

class PlayerController {
  PlayerController(this._ref);

  final Ref _ref;

  Future<void> togglePlayPause() async {
    final handler = await _ref.read(audioHandlerProvider.future);
    final playing = handler.playbackState.value.playing;
    if (playing) {
      await handler.pause();
    } else {
      await handler.play();
    }
  }

  Future<void> playTrack(Track track) async {
    final handler = await _ref.read(audioHandlerProvider.future);
    await handler.addTrackAndPlay(track);
  }

  Future<void> playTracks(List<Track> tracks, {int startIndex = 0}) async {
    final handler = await _ref.read(audioHandlerProvider.future);
    await handler.replaceQueueWithTracks(tracks, startIndex: startIndex);
  }

  Future<void> seek(Duration position) async {
    final handler = await _ref.read(audioHandlerProvider.future);
    await handler.seek(position);
  }

  Future<void> skipNext() async {
    final handler = await _ref.read(audioHandlerProvider.future);
    await handler.skipToNext();
  }

  Future<void> skipPrevious() async {
    final handler = await _ref.read(audioHandlerProvider.future);
    await handler.skipToPrevious();
  }

  Future<void> playQueueIndex(int index) async {
    final handler = await _ref.read(audioHandlerProvider.future);
    await handler.skipToQueueItem(index);
  }
}
