import 'dart:async';
import 'dart:io';

import 'package:mini_music_test_app/data/datasources/download_data_source.dart';
import 'package:mini_music_test_app/data/datasources/download_storage_data_source.dart';
import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/download_repository.dart';
import 'package:path/path.dart' as p;

class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(
    this._downloadDataSource,
    this._storageDataSource,
    this._downloadPathProvider,
  );

  final DownloadDataSource _downloadDataSource;
  final DownloadStorageDataSource _storageDataSource;
  final Future<String> Function() _downloadPathProvider;

  @override
  Stream<DownloadInfo> downloadTrack(Track track) {
    final controller = StreamController<DownloadInfo>();
    StreamSubscription<double>? subscription;

    () async {
      try {
        if (_isLocalAsset(track.audioUrl)) {
          final downloadPath = track.audioUrl;
          final start = DownloadInfo(
            trackId: track.id,
            status: DownloadStatus.downloading,
            progress: 0.0,
            localPath: downloadPath,
          );
          await _storageDataSource.save(start);
          if (!controller.isClosed) {
            controller.add(start);
          }

          await Future.delayed(const Duration(milliseconds: 600));
          final completed = start.copyWith(
            status: DownloadStatus.downloaded,
            progress: 1.0,
          );
          await _storageDataSource.save(completed);
          if (!controller.isClosed) {
            controller.add(completed);
            await controller.close();
          }
          return;
        }

        final dirPath = await _downloadPathProvider();
        final directory = Directory(dirPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final extension = _extensionFromUrl(track.audioUrl);
        final savePath = p.join(dirPath, '${track.id}.$extension');

        if (await _downloadDataSource.exists(savePath)) {
          final info = DownloadInfo(
            trackId: track.id,
            status: DownloadStatus.downloaded,
            progress: 1.0,
            localPath: savePath,
          );
          await _storageDataSource.save(info);
          controller.add(info);
          await controller.close();
          return;
        }

        final initial = DownloadInfo(
          trackId: track.id,
          status: DownloadStatus.downloading,
          progress: 0,
          localPath: savePath,
        );
        await _storageDataSource.save(initial);
        controller.add(initial);

        subscription = _downloadDataSource
            .download(track.audioUrl, savePath)
            .listen((progress) {
          final update = initial.copyWith(
            progress: progress.clamp(0, 1),
            status: DownloadStatus.downloading,
          );
          controller.add(update);
          unawaited(_storageDataSource.save(update));
        }, onError: (Object error, StackTrace stackTrace) async {
          final failed = initial.copyWith(
            status: DownloadStatus.failed,
            error: error.toString(),
          );
          await _storageDataSource.save(failed);
          if (!controller.isClosed) {
            controller.add(failed);
            controller.addError(error, stackTrace);
            await controller.close();
          }
        }, onDone: () async {
          final completed = initial.copyWith(
            status: DownloadStatus.downloaded,
            progress: 1.0,
          );
          await _storageDataSource.save(completed);
          controller.add(completed);
          await controller.close();
        });
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
          await controller.close();
        }
      }
    }();

    controller.onCancel = () async {
      await subscription?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<DownloadInfo> getDownloadInfo(String trackId) async {
    final cached = _storageDataSource.read(trackId);
    if (cached == null) {
      return DownloadInfo.initial(trackId);
    }
    if (cached.status == DownloadStatus.downloaded &&
        !_isLocalAsset(cached.localPath ?? '') &&
        (cached.localPath == null ||
            !await _downloadDataSource.exists(cached.localPath!))) {
      final reset = DownloadInfo.initial(trackId);
      await _storageDataSource.save(reset);
      return reset;
    }
    return cached;
  }

  @override
  Future<List<DownloadInfo>> loadAllDownloads() async {
    final items = _storageDataSource.readAll();
    final cleaned = <DownloadInfo>[];
    for (final item in items) {
      if (item.status == DownloadStatus.downloaded &&
          item.localPath != null &&
          !_isLocalAsset(item.localPath!)) {
        final exists = await _downloadDataSource.exists(item.localPath!);
        if (!exists) {
          final reset = DownloadInfo.initial(item.trackId);
          await _storageDataSource.save(reset);
          cleaned.add(reset);
          continue;
        }
      }
      cleaned.add(item);
    }
    return cleaned;
  }

  @override
  Future<void> removeDownload(String trackId) async {
    final cached = _storageDataSource.read(trackId);
    if (cached != null && cached.localPath != null && !_isLocalAsset(cached.localPath!)) {
      await _downloadDataSource.delete(cached.localPath!);
    }
    await _storageDataSource.remove(trackId);
  }

  String _extensionFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isEmpty) {
      return 'mp3';
    }
    final last = segments.last;
    final parts = last.split('.');
    if (parts.length < 2) {
      return 'mp3';
    }
    return parts.last;
  }

  bool _isLocalAsset(String path) => path.startsWith('assets/');
}
