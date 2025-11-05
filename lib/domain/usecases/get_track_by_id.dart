import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/domain/repositories/track_repository.dart';

class GetTrackById {
  const GetTrackById(this.repository);

  final TrackRepository repository;

  Future<Track?> call(String id) => repository.findById(id);
}
