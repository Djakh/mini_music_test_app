import 'package:mini_music_test_app/domain/entities/queue_state.dart';

abstract class QueueRepository {
  Future<void> saveQueue(QueueState state);
  Future<QueueState> loadQueue();
}
