import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mini_music_test_app/data/datasources/catalog_local_data_source.dart';
import 'package:mini_music_test_app/data/datasources/download_data_source.dart';
import 'package:mini_music_test_app/data/datasources/download_storage_data_source.dart';
import 'package:mini_music_test_app/data/datasources/queue_storage_data_source.dart';
import 'package:mini_music_test_app/data/repositories/download_repository_impl.dart';
import 'package:mini_music_test_app/data/repositories/queue_repository_impl.dart';
import 'package:mini_music_test_app/data/repositories/track_repository_impl.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/download_repository.dart';
import 'package:mini_music_test_app/domain/repositories/queue_repository.dart';
import 'package:mini_music_test_app/domain/repositories/track_repository.dart';
import 'package:mini_music_test_app/domain/usecases/get_catalog.dart';
import 'package:mini_music_test_app/services/mini_audio_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final downloadBoxProvider = Provider<Box>((ref) => throw UnimplementedError('downloadBoxProvider must be overridden.'));

final queueBoxProvider = Provider<Box>((ref) => throw UnimplementedError('queueBoxProvider must be overridden.'));

final catalogDataSourceProvider = Provider<CatalogLocalDataSource>((ref) => AssetCatalogDataSource());

final trackRepositoryProvider = Provider<TrackRepository>(
  (ref) => TrackRepositoryImpl(ref.watch(catalogDataSourceProvider)),
);

final downloadDataSourceProvider = Provider<DownloadDataSource>(
  (ref) => DioDownloadDataSource(ref.watch(dioProvider)),
);

final downloadStorageDataSourceProvider = Provider<DownloadStorageDataSource>(
  (ref) => DownloadStorageDataSource(ref.watch(downloadBoxProvider)),
);

final queueStorageDataSourceProvider = Provider<QueueStorageDataSource>(
  (ref) => QueueStorageDataSource(ref.watch(queueBoxProvider)),
);

final downloadRepositoryProvider = Provider<DownloadRepository>(
  (ref) => DownloadRepositoryImpl(
    ref.watch(downloadDataSourceProvider),
    ref.watch(downloadStorageDataSourceProvider),
    () async {
      final dir = await getApplicationSupportDirectory();
      return p.join(dir.path, 'downloads');
    },
  ),
);

final queueRepositoryProvider = Provider<QueueRepository>(
  (ref) => QueueRepositoryImpl(ref.watch(queueStorageDataSourceProvider)),
);

final getCatalogProvider = Provider<GetCatalog>((ref) => GetCatalog(ref.watch(trackRepositoryProvider)));

final catalogProvider = FutureProvider<List<Track>>((ref) async {
  final getCatalog = ref.watch(getCatalogProvider);
  return getCatalog();
});

final audioHandlerProvider = FutureProvider<MiniAudioHandler>((ref) async {
  final audioHandler = await AudioService.init(
    builder: () => MiniAudioHandler(
      trackRepository: ref.watch(trackRepositoryProvider),
      downloadRepository: ref.watch(downloadRepositoryProvider),
      queueRepository: ref.watch(queueRepositoryProvider),
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'mini_music_player_channel',
      androidNotificationChannelName: 'Mini Music Player',
      androidNotificationOngoing: true,
    ),
  );
  final handler = audioHandler as MiniAudioHandler;
  await handler.init();
  ref.onDispose(handler.dispose);
  return handler;
});

final playbackStateStreamProvider = StreamProvider<PlaybackState>((ref) async* {
  final handler = await ref.watch(audioHandlerProvider.future);
  yield* handler.playbackState;
});

final mediaItemStreamProvider = StreamProvider<MediaItem?>((ref) async* {
  final handler = await ref.watch(audioHandlerProvider.future);
  yield* handler.mediaItem;
});

final queueStreamProvider = StreamProvider<List<MediaItem>>((ref) async* {
  final handler = await ref.watch(audioHandlerProvider.future);
  yield* handler.queue;
});

final positionStreamProvider = StreamProvider<Duration>((ref) async* {
  final handler = await ref.watch(audioHandlerProvider.future);
  yield* handler.positionStream;
});

final durationStreamProvider = StreamProvider<Duration?>((ref) async* {
  final handler = await ref.watch(audioHandlerProvider.future);
  yield* handler.durationStream;
});

final bufferedPositionStreamProvider = StreamProvider<Duration>((ref) async* {
  final handler = await ref.watch(audioHandlerProvider.future);
  yield* handler.bufferedPositionStream;
});

final playingStreamProvider = StreamProvider<bool>((ref) async* {
  final handler = await ref.watch(audioHandlerProvider.future);
  yield* handler.playingStream;
});
