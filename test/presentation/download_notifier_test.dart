import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_music_test_app/core/di/providers.dart';
import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/download_repository.dart';
import 'package:mini_music_test_app/presentation/notifiers/download_notifier.dart';
import 'package:mini_music_test_app/services/mini_audio_handler.dart';
import 'package:mocktail/mocktail.dart';

class _MockDownloadRepository extends Mock implements DownloadRepository {}

class _MockAudioHandler extends Mock implements MiniAudioHandler {}

void main() {
  late ProviderContainer container;
  late _MockDownloadRepository repository;
  late _MockAudioHandler audioHandler;

  const track = Track(
    id: 'track1',
    title: 'Sample',
    artist: 'Artist',
    duration: 120,
    audioUrl: 'https://example.com/track.mp3',
    coverUrl: 'assets/covers/sunrise.png',
  );

  setUp(() {
    repository = _MockDownloadRepository();
    audioHandler = _MockAudioHandler();

    when(repository.loadAllDownloads).thenAnswer((_) async => const []);
    when(() => audioHandler.refreshSourceForTrack(any(), resumeIfCurrent: any(named: 'resumeIfCurrent')))
        .thenAnswer((_) async {});

    container = ProviderContainer(overrides: [
      downloadRepositoryProvider.overrideWithValue(repository),
      audioHandlerProvider.overrideWith((ref) => Future.value(audioHandler)),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  test('startDownload updates state and refreshes audio handler on completion', () async {
    final progressController = StreamController<DownloadInfo>();

    when(() => repository.downloadTrack(track)).thenAnswer((invocation) {
      return progressController.stream;
    });

    final notifier = container.read(downloadNotifierProvider.notifier);
    await Future<void>.delayed(Duration.zero); // wait for initial load

    await notifier.startDownload(track);

    final inProgress = DownloadInfo(
      trackId: track.id,
      status: DownloadStatus.downloading,
      progress: 0.5,
    );
    progressController.add(inProgress);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(downloadNotifierProvider)[track.id], inProgress);

    final completed = DownloadInfo(
      trackId: track.id,
      status: DownloadStatus.downloaded,
      progress: 1.0,
      localPath: '/tmp/${track.id}.mp3',
    );
    progressController.add(completed);
    await progressController.close();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(downloadNotifierProvider)[track.id], completed);
    verify(() => audioHandler.refreshSourceForTrack(track.id, resumeIfCurrent: true)).called(1);
  });
}
