import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:mini_music_test_app/domain/entities/track.dart';

class TrackModel extends Track {
  const TrackModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.duration,
    required super.audioUrl,
    required super.coverUrl,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      duration: json['duration'] as int,
      audioUrl: json['audioUrl'] as String,
      coverUrl: json['coverUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration': duration,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
    };
  }

  static Future<List<TrackModel>> loadFromAsset(String path) async {
    final data = await rootBundle.loadString(path);
    final list = jsonDecode(data) as List<dynamic>;
    return list.map((e) => TrackModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
