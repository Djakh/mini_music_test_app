import 'package:flutter_test/flutter_test.dart';
import 'package:mini_music_test_app/data/datasources/catalog_local_data_source.dart';
import 'package:mini_music_test_app/data/models/track_model.dart';
import 'package:mini_music_test_app/data/repositories/track_repository_impl.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';

class _FakeCatalogDataSource implements CatalogLocalDataSource {
  _FakeCatalogDataSource(this._tracks);

  final List<TrackModel> _tracks;

  @override
  Future<List<TrackModel>> loadCatalog() async => _tracks;
}

void main() {
  late TrackRepositoryImpl repository;
  late List<TrackModel> sampleTracks;

  setUp(() {
    sampleTracks = const [
      TrackModel(
        id: '1',
        title: 'Sunrise',
        artist: 'Lofi Lab',
        duration: 180,
        audioUrl: 'https://example.com/sunrise.mp3',
        coverUrl: 'assets/covers/sunrise.png',
      ),
      TrackModel(
        id: '2',
        title: 'Night Drive',
        artist: 'Synth Waves',
        duration: 200,
        audioUrl: 'https://example.com/night.mp3',
        coverUrl: 'assets/covers/night_drive.png',
      ),
    ];
    repository = TrackRepositoryImpl(_FakeCatalogDataSource(sampleTracks));
  });

  test('fetchCatalog returns all tracks', () async {
    final tracks = await repository.fetchCatalog();
    expect(tracks, isA<List<Track>>());
    expect(tracks.length, sampleTracks.length);
  });

  test('searchTracks matches by title or artist (case insensitive)', () async {
    final byTitle = await repository.searchTracks('sun');
    expect(byTitle.map((e) => e.id), ['1']);

    final byArtist = await repository.searchTracks('waves');
    expect(byArtist.map((e) => e.id), ['2']);
  });
}
