import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/repositories/download_repository.dart';

class LoadDownloads {
  const LoadDownloads(this.repository);

  final DownloadRepository repository;

  Future<List<DownloadInfo>> call() => repository.loadAllDownloads();
}
