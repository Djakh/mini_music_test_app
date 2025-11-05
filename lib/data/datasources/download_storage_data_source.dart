import 'package:hive/hive.dart';
import 'package:mini_music_test_app/domain/entities/download_info.dart';

class DownloadStorageDataSource {
  DownloadStorageDataSource(this.box);

  final Box box;

  Future<void> save(DownloadInfo info) async {
    await box.put(info.trackId, {
      'status': info.status.name,
      'progress': info.progress,
      'localPath': info.localPath,
      'error': info.error,
    });
  }

  DownloadInfo? read(String trackId) {
    final raw = box.get(trackId) as Map<dynamic, dynamic>?;
    if (raw == null) {
      return null;
    }
    final statusName = raw['status'] as String?;
    return DownloadInfo(
      trackId: trackId,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => DownloadStatus.notDownloaded,
      ),
      progress: (raw['progress'] as num?)?.toDouble() ?? 0,
      localPath: raw['localPath'] as String?,
      error: raw['error'] as String?,
    );
  }

  Future<void> remove(String trackId) => box.delete(trackId);

  List<DownloadInfo> readAll() {
    return box.keys
        .map((key) => key as String)
        .map((key) => read(key) ?? DownloadInfo.initial(key))
        .toList();
  }
}
