import 'package:mini_music_test_app/data/datasources/catalog_local_data_source.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/track_repository.dart';

class TrackRepositoryImpl implements TrackRepository {
  TrackRepositoryImpl(this._catalogLocalDataSource);

  final CatalogLocalDataSource _catalogLocalDataSource;

  List<Track>? _cache;

  Future<List<Track>> _ensureCache() async {
    if (_cache != null) {
      return _cache!;
    }
    final tracks = await _catalogLocalDataSource.loadCatalog();
    _cache = tracks;
    return tracks;
  }

  @override
  Future<List<Track>> fetchCatalog() => _ensureCache();

  @override
  Future<Track?> findById(String id) async {
    final tracks = await _ensureCache();
    try {
      return tracks.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Track>> searchTracks(String query) async {
    final tracks = await _ensureCache();
    if (query.isEmpty) {
      return tracks;
    }
    final lower = query.toLowerCase();
    return tracks
        .where((track) =>
            track.title.toLowerCase().contains(lower) ||
            track.artist.toLowerCase().contains(lower))
        .toList();
  }
}
