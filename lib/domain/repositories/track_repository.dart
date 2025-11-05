import 'package:mini_music_test_app/domain/entities/track.dart';

abstract class TrackRepository {
  Future<List<Track>> fetchCatalog();
  Future<List<Track>> searchTracks(String query);
  Future<Track?> findById(String id);
}
