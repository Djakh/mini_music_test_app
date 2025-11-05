import 'package:mini_music_test_app/domain/entities/queue_state.dart';
import 'package:mini_music_test_app/domain/repositories/queue_repository.dart';

class SaveQueueState {
  const SaveQueueState(this.repository);

  final QueueRepository repository;

  Future<void> call(QueueState state) => repository.saveQueue(state);
}
