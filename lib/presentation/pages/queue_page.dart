import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_music_test_app/core/di/providers.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/presentation/providers/player_controller_provider.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueStreamProvider);
    final currentMediaItem = ref.watch(mediaItemStreamProvider).value;
    final catalogAsync = ref.watch(catalogProvider);
    final controller = ref.watch(playerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback Queue'),
      ),
      body: queueAsync.when(
        data: (queueItems) {
          if (queueItems.isEmpty) {
            return const _EmptyQueue();
          }
          final catalog = catalogAsync.maybeWhen(data: (value) => value, orElse: () => <Track>[]);
          return ListView.separated(
            itemBuilder: (context, index) {
              final item = queueItems[index];
              Track? matched;
              for (final track in catalog) {
                if (track.id == item.id) {
                  matched = track;
                  break;
                }
              }
              final track = matched ??
                  Track(
                    id: item.id,
                    title: item.title,
                    artist: item.artist ?? 'Unknown artist',
                    duration: item.duration?.inSeconds ?? 0,
                    audioUrl: item.extras?['audioUrl'] as String? ?? '',
                    coverUrl: item.extras?['coverUrl'] as String? ?? '',
                  );
              final isCurrent = currentMediaItem?.id == item.id;
              return ListTile(
                leading: _CoverThumbnail(path: track.coverUrl),
                title: Text(track.title),
                subtitle: Text(track.artist),
                trailing: isCurrent ? const Icon(Icons.equalizer) : null,
                selected: isCurrent,
                onTap: () => controller.playQueueIndex(index),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: queueItems.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Failed to load queue: ${error.toString()}'),
        ),
      ),
    );
  }
}

class _CoverThumbnail extends StatelessWidget {
  const _CoverThumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return const _PlaceholderCover();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        path,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PlaceholderCover(),
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.queue_music, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Queue is empty. Start playing a track to build it automatically.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
