import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/entities/queue_state.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/download_repository.dart';
import 'package:mini_music_test_app/domain/repositories/queue_repository.dart';
import 'package:mini_music_test_app/domain/repositories/track_repository.dart';

class MiniAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  MiniAudioHandler({
    required TrackRepository trackRepository,
    required DownloadRepository downloadRepository,
    required QueueRepository queueRepository,
  })  : _trackRepository = trackRepository,
        _downloadRepository = downloadRepository,
        _queueRepository = queueRepository,
        _player = AudioPlayer();

  final TrackRepository _trackRepository;
  final DownloadRepository _downloadRepository;
  final QueueRepository _queueRepository;
  final AudioPlayer _player;
  late final ConcatenatingAudioSource _playlist;

  List<Track> _catalog = const [];
  Timer? _positionPersistTimer;
  bool _resumeAfterInterruption = false;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _resumeAfterInterruption = _player.playing;
            unawaited(pause());
            break;
          case AudioInterruptionType.duck:
            unawaited(_player.setVolume(0.2));
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_resumeAfterInterruption) {
              unawaited(play());
            }
            _resumeAfterInterruption = false;
            break;
          case AudioInterruptionType.duck:
            unawaited(_player.setVolume(1.0));
            break;
        }
      }
    });
    session.becomingNoisyEventStream.listen((_) {
      _resumeAfterInterruption = _player.playing;
      unawaited(pause());
    });
    _playlist = ConcatenatingAudioSource(children: []);

    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen(_handleCurrentIndex);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });

    _player.positionStream.listen((_) {
      _scheduleQueuePersist();
    });

    _catalog = await _trackRepository.fetchCatalog();
    final storedQueue = await _queueRepository.loadQueue();

    if (storedQueue.trackIds.isEmpty) {
      queue.add(const <MediaItem>[]);
      await _playlist.clear();
      await _player.setAudioSource(_playlist);
    } else {
      final items = <MediaItem>[];
      for (final id in storedQueue.trackIds) {
        final track = await _trackRepository.findById(id);
        if (track != null) {
          items.add(_mediaItemFromTrack(track));
        }
      }
      final reversedItems = items.reversed.toList();
      queue.add(reversedItems);
      if (items.isNotEmpty) {
        await _playlist.addAll(await Future.wait(reversedItems.map(_audioSourceFor)));
      }
      final resolvedIndex = storedQueue.currentTrackId == null
          ? (reversedItems.isNotEmpty ? 0 : null)
          : reversedItems.indexWhere((item) => item.id == storedQueue.currentTrackId);
      final initialIndex =
          resolvedIndex == null || resolvedIndex < 0 ? (reversedItems.isNotEmpty ? 0 : null) : resolvedIndex;
      await _player.setAudioSource(
        _playlist,
        initialIndex: initialIndex,
        initialPosition: initialIndex != null
            ? Duration(milliseconds: storedQueue.positionMilliseconds)
            : null,
      );
    }
  }

  Future<void> addTrackAndPlay(Track track) async {
    final item = _mediaItemFromTrack(track);
    final currentItems = [...queue.value]..removeWhere((element) => element.id == item.id);
    final updatedItems = [item, ...currentItems];
    queue.add(updatedItems);

    await _playlist.clear();
    await _playlist.addAll(await Future.wait(updatedItems.map(_audioSourceFor)));
    await _player.setAudioSource(_playlist, initialIndex: 0, initialPosition: Duration.zero);
    await play();
    mediaItem.add(item);
    await _persistQueueState();
  }

  Future<void> refreshSourceForTrack(String trackId, {bool resumeIfCurrent = true}) async {
    final index = queue.value.indexWhere((element) => element.id == trackId);
    if (index == -1) {
      return;
    }
    final item = queue.value[index];
    final wasPlaying = _player.playing;
    final currentPosition = _player.position;
    await _playlist.removeAt(index);
    await _playlist.insert(index, await _audioSourceFor(item));
    if (_player.currentIndex == index) {
      await _player.seek(currentPosition, index: index);
      if (resumeIfCurrent && wasPlaying) {
        await _player.play();
      }
    }
  }

  Future<void> replaceQueueWithTracks(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) {
      queue.add(const <MediaItem>[]);
      await _playlist.clear();
      await _player.stop();
      await _persistQueueState();
      return;
    }
    final items = tracks.map(_mediaItemFromTrack).toList();
    final ordered = items.reversed.toList();
    queue.add(ordered);
    await _playlist.clear();
    await _playlist.addAll(await Future.wait(ordered.map(_audioSourceFor)));
    final correctedIndex = ordered.length - 1 - startIndex;
    await _player.setAudioSource(_playlist, initialIndex: correctedIndex < 0 ? 0 : correctedIndex);
    await play();
    await _persistQueueState();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) {
      return;
    }
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    await _player.play();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> dispose() async {
    await _player.dispose();
    _positionPersistTimer?.cancel();
  }

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  Stream<bool> get playingStream => _player.playingStream;

  MediaItem _mediaItemFromTrack(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      duration: Duration(seconds: track.duration),
      extras: {
        'audioUrl': track.audioUrl,
        'coverUrl': track.coverUrl,
      },
    );
  }

  Future<AudioSource> _audioSourceFor(MediaItem mediaItem) async {
    final extras = mediaItem.extras ?? {};
    final url = extras['audioUrl'] as String? ?? '';

    if (_isLocalAsset(url)) {
      return AudioSource.asset(url, tag: mediaItem);
    }

    final downloadInfo = await _downloadRepository.getDownloadInfo(mediaItem.id);

    if (downloadInfo.status == DownloadStatus.downloaded &&
        downloadInfo.localPath != null) {
      return AudioSource.uri(Uri.file(downloadInfo.localPath!), tag: mediaItem);
    }

    if (url.startsWith('http')) {
      return AudioSource.uri(Uri.parse(url), tag: mediaItem);
    }

    return AudioSource.uri(Uri.file(url), tag: mediaItem);
  }

  bool _isLocalAsset(String path) => path.startsWith('assets/');

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  void _handleCurrentIndex(int? index) {
    if (index == null || index < 0 || index >= queue.value.length) {
      mediaItem.add(null);
    } else {
      mediaItem.add(queue.value[index]);
    }
    _scheduleQueuePersist();
  }

  void _scheduleQueuePersist() {
    _positionPersistTimer?.cancel();
    _positionPersistTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_persistQueueState());
    });
  }

  Future<void> _persistQueueState() async {
    final items = queue.value;
    final current = _player.currentIndex;
    final currentItem =
        current != null && current >= 0 && current < items.length ? items[current] : null;
    final state = QueueState(
      trackIds: items.map((e) => e.id).toList().reversed.toList(),
      currentTrackId: currentItem?.id,
      positionMilliseconds: _player.position.inMilliseconds,
    );
    await _queueRepository.saveQueue(state);
  }
}
