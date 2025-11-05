import 'package:equatable/equatable.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

class DownloadInfo extends Equatable {
  const DownloadInfo({
    required this.trackId,
    required this.status,
    required this.progress,
    this.localPath,
    this.error,
  });

  final String trackId;
  final DownloadStatus status;
  final double progress; // 0.0 - 1.0
  final String? localPath;
  final String? error;

  DownloadInfo copyWith({
    DownloadStatus? status,
    double? progress,
    String? localPath,
    String? error,
  }) {
    return DownloadInfo(
      trackId: trackId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
    );
  }

  static DownloadInfo initial(String trackId) => DownloadInfo(
        trackId: trackId,
        status: DownloadStatus.notDownloaded,
        progress: 0,
      );

  @override
  List<Object?> get props => [trackId, status, progress, localPath, error];
}
