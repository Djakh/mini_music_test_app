import 'package:mini_music_test_app/data/datasources/queue_storage_data_source.dart';
import 'package:mini_music_test_app/domain/entities/queue_state.dart';
import 'package:mini_music_test_app/domain/repositories/queue_repository.dart';

class QueueRepositoryImpl implements QueueRepository {
  QueueRepositoryImpl(this._storageDataSource);

  final QueueStorageDataSource _storageDataSource;

  @override
  Future<QueueState> loadQueue() async {
    return _storageDataSource.read() ?? QueueState.empty;
  }

  @override
  Future<void> saveQueue(QueueState state) => _storageDataSource.save(state);
}
