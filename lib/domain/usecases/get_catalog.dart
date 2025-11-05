import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/track_repository.dart';

class GetCatalog {
  const GetCatalog(this.repository);

  final TrackRepository repository;

  Future<List<Track>> call() => repository.fetchCatalog();
}
