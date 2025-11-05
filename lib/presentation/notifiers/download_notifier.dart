import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_music_test_app/core/di/providers.dart';
import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/download_repository.dart';
import 'package:mini_music_test_app/services/mini_audio_handler.dart';

final downloadNotifierProvider = StateNotifierProvider<DownloadNotifier, Map<String, DownloadInfo>>(
  (ref) {
    final repository = ref.watch(downloadRepositoryProvider);
    final notifier = DownloadNotifier(ref, repository);
    notifier.load();
    ref.onDispose(notifier.dispose);
    return notifier;
  },
);

class DownloadNotifier extends StateNotifier<Map<String, DownloadInfo>> {
  DownloadNotifier(this._ref, this._repository) : super({});

  final Ref _ref;
  final DownloadRepository _repository;
  final Map<String, StreamSubscription<DownloadInfo>> _subscriptions = {};

  Future<void> load() async {
    final downloads = await _repository.loadAllDownloads();
    state = {
      for (final info in downloads) info.trackId: info,
    };
  }

  Future<void> startDownload(Track track) async {
    await _subscriptions[track.id]?.cancel();
    final stream = _repository.downloadTrack(track);
    final subscription = stream.listen((info) async {
      state = {
        ...state,
        info.trackId: info,
      };
      if (info.status == DownloadStatus.downloaded) {
        final handler = await _ref.read(audioHandlerProvider.future);
        await handler.refreshSourceForTrack(track.id);
      }
    }, onError: (_) {
      // errors already pushed into state via addError, no-op
    }, onDone: () {
      _subscriptions.remove(track.id);
    });
    _subscriptions[track.id] = subscription;
  }

  Future<void> removeDownload(String trackId) async {
    await _subscriptions[trackId]?.cancel();
    _subscriptions.remove(trackId);
    await _repository.removeDownload(trackId);
    final existing = state[trackId];
    state = {
      ...state,
      trackId: (existing ?? DownloadInfo.initial(trackId)).copyWith(
        status: DownloadStatus.notDownloaded,
        progress: 0,
        localPath: null,
        error: null,
      ),
    };
  }

  DownloadInfo infoFor(String trackId) {
    return state[trackId] ?? DownloadInfo.initial(trackId);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}
