import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_music_test_app/core/di/providers.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredCatalogProvider = Provider<AsyncValue<List<Track>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim();
  final catalogAsync = ref.watch(catalogProvider);
  return catalogAsync.whenData((tracks) {
    if (query.isEmpty) {
      return tracks;
    }
    final lower = query.toLowerCase();
    return tracks
        .where((track) =>
            track.title.toLowerCase().contains(lower) ||
            track.artist.toLowerCase().contains(lower))
        .toList();
  });
});
