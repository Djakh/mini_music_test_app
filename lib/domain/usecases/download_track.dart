import 'dart:async';

import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/download_repository.dart';

class DownloadTrack {
  const DownloadTrack(this.repository);

  final DownloadRepository repository;

  Stream<DownloadInfo> call(Track track) => repository.downloadTrack(track);
}
