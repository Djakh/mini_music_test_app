import 'package:mini_music_test_app/domain/entities/queue_state.dart';
import 'package:mini_music_test_app/domain/repositories/queue_repository.dart';

class LoadQueueState {
  const LoadQueueState(this.repository);

  final QueueRepository repository;

  Future<QueueState> call() => repository.loadQueue();
}
