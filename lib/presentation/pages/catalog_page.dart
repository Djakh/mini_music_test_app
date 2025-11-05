import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_music_test_app/presentation/pages/queue_page.dart';
import 'package:mini_music_test_app/presentation/providers/catalog_providers.dart';
import 'package:mini_music_test_app/presentation/providers/player_controller_provider.dart';
import 'package:mini_music_test_app/presentation/widgets/download_button.dart';
import 'package:mini_music_test_app/presentation/widgets/mini_player.dart';
import 'package:mini_music_test_app/presentation/widgets/track_tile.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(filteredCatalogProvider);
    final playerController = ref.watch(playerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Music Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QueuePage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by title or artist',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
              ),
            ),
            Expanded(
              child: catalogAsync.when(
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return _EmptyState(
                      message: ref.read(searchQueryProvider).isEmpty
                          ? 'No tracks available'
                          : 'No results for "${ref.read(searchQueryProvider)}"',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return TrackTile(
                        track: track,
                        onTap: () => playerController.playTrack(track),
                        trailing: DownloadButton(track: track),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: tracks.length,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _EmptyState(
                  message: 'Failed to load catalog. ${error.toString()}',
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
