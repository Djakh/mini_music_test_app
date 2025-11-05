import 'package:equatable/equatable.dart';

class Track extends Equatable {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.audioUrl,
    required this.coverUrl,
  });

  final String id;
  final String title;
  final String artist;
  final int duration; // seconds
  final String audioUrl;
  final String coverUrl;

  @override
  List<Object?> get props => [id, title, artist, duration, audioUrl, coverUrl];
}
