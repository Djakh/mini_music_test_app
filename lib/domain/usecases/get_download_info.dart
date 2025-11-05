import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/repositories/download_repository.dart';

class GetDownloadInfo {
  const GetDownloadInfo(this.repository);

  final DownloadRepository repository;

  Future<DownloadInfo> call(String trackId) => repository.getDownloadInfo(trackId);
}
