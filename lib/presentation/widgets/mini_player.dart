import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_music_test_app/core/di/providers.dart';
import 'package:mini_music_test_app/core/utils/duration_formatter.dart';
import 'package:mini_music_test_app/presentation/providers/player_controller_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemAsync = ref.watch(mediaItemStreamProvider);
    return mediaItemAsync.when(
      data: (mediaItem) {
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }
        final playbackState = ref.watch(playbackStateStreamProvider).value;
        final positionAsync = ref.watch(positionStreamProvider);
        final bufferedAsync = ref.watch(bufferedPositionStreamProvider);
        final durationAsync = ref.watch(durationStreamProvider);

        final position = positionAsync.maybeWhen(
          data: (value) => value,
          orElse: () => playbackState?.updatePosition ?? Duration.zero,
        );
        final buffered = bufferedAsync.maybeWhen(
          data: (value) => value,
          orElse: () => playbackState?.bufferedPosition ?? Duration.zero,
        );
        final duration = durationAsync.maybeWhen(
          data: (value) => value ?? mediaItem.duration ?? Duration.zero,
          orElse: () => mediaItem.duration ?? Duration.zero,
        );
        final playing = playbackState?.playing ?? false;
        final controller = ref.watch(playerControllerProvider);
        final coverUrl = mediaItem.extras?['coverUrl'] as String?;
        final progressMax = max(duration.inMilliseconds.toDouble(), 1);
        final positionMs = position.inMilliseconds.toDouble().clamp(0, progressMax);
        final bufferedMs = min(buffered.inMilliseconds.toDouble(), progressMax);

        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            top: 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (coverUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        coverUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mediaItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mediaItem.artist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () => controller.skipPrevious(),
                  ),
                  IconButton(
                    icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
                    iconSize: 36,
                    onPressed: () => controller.togglePlayPause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () => controller.skipNext(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(formatDuration(position)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: positionMs.toDouble(),
                        max: progressMax.toDouble(),
                        onChanged: (value) {},
                        onChangeEnd: (value) => controller.seek(Duration(milliseconds: value.toInt())),
                      ),
                    ),
                  ),
                  Text(formatDuration(duration)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 50, right: 16, top: 6, bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ),
                    child: LinearProgressIndicator(
                      value: progressMax == 0 ? 0 : bufferedMs / progressMax,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.secondary.withOpacity(0.35),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
