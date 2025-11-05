import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/track_repository.dart';

class SearchTracks {
  const SearchTracks(this.repository);

  final TrackRepository repository;

  Future<List<Track>> call(String query) => repository.searchTracks(query);
}
