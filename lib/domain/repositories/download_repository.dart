import 'dart:async';

import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';

abstract class DownloadRepository {
  Stream<DownloadInfo> downloadTrack(Track track);
  Future<DownloadInfo> getDownloadInfo(String trackId);
  Future<void> removeDownload(String trackId);
  Future<List<DownloadInfo>> loadAllDownloads();
}
