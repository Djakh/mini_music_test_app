import 'package:mini_music_test_app/domain/repositories/download_repository.dart';

class RemoveDownload {
  const RemoveDownload(this.repository);

  final DownloadRepository repository;

  Future<void> call(String trackId) => repository.removeDownload(trackId);
}
