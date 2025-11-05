import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_music_test_app/domain/entities/download_info.dart';
import 'package:mini_music_test_app/domain/entities/track.dart';
import 'package:mini_music_test_app/presentation/notifiers/download_notifier.dart';

class DownloadButton extends ConsumerWidget {
  const DownloadButton({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadNotifierProvider);
    final info = downloads[track.id] ?? DownloadInfo.initial(track.id);

    switch (info.status) {
      case DownloadStatus.notDownloaded:
        return IconButton(
          icon: const Icon(Icons.download),
          tooltip: 'Download for offline playback',
          onPressed: () => ref.read(downloadNotifierProvider.notifier).startDownload(track),
        );
      case DownloadStatus.downloading:
        return SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: info.progress > 0 ? info.progress : null),
              const Icon(Icons.downloading, size: 16),
            ],
          ),
        );
      case DownloadStatus.downloaded:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_done),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Remove downloaded file',
              onPressed: () => ref.read(downloadNotifierProvider.notifier).removeDownload(track.id),
            ),
          ],
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Retry download',
          onPressed: () => ref.read(downloadNotifierProvider.notifier).startDownload(track),
        );
    }
  }
}
