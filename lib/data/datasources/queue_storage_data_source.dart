import 'package:hive/hive.dart';
import 'package:mini_music_test_app/domain/entities/queue_state.dart';

class QueueStorageDataSource {
  QueueStorageDataSource(this.box);

  final Box box;

  Future<void> save(QueueState state) async {
    await box.put('state', {
      'trackIds': state.trackIds,
      'currentTrackId': state.currentTrackId,
      'positionMs': state.positionMilliseconds,
    });
  }

  QueueState? read() {
    final raw = box.get('state') as Map<dynamic, dynamic>?;
    if (raw == null) {
      return null;
    }
    final trackIds = (raw['trackIds'] as List<dynamic>? ?? []).cast<String>();
    return QueueState(
      trackIds: trackIds,
      currentTrackId: raw['currentTrackId'] as String?,
      positionMilliseconds: (raw['positionMs'] as num?)?.toInt() ?? 0,
    );
  }
}
