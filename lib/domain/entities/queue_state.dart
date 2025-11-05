import 'package:equatable/equatable.dart';

class QueueState extends Equatable {
  const QueueState({
    required this.trackIds,
    this.currentTrackId,
    this.positionMilliseconds = 0,
  });

  final List<String> trackIds;
  final String? currentTrackId;
  final int positionMilliseconds;

  QueueState copyWith({
    List<String>? trackIds,
    String? currentTrackId,
    int? positionMilliseconds,
  }) {
    return QueueState(
      trackIds: trackIds ?? this.trackIds,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      positionMilliseconds: positionMilliseconds ?? this.positionMilliseconds,
    );
  }

  static const empty = QueueState(trackIds: []);

  @override
  List<Object?> get props => [trackIds, currentTrackId, positionMilliseconds];
}
