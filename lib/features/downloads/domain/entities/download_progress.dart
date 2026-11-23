enum DownloadStatus { idle, queued, downloading, completed, failed, cancelled }

/// Represents the real-time download state and progress for a track.
class DownloadProgress {
  const DownloadProgress({
    required this.trackId,
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  final String trackId;
  final DownloadStatus status;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isQueued => status == DownloadStatus.queued;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isCancelled => status == DownloadStatus.cancelled;

  DownloadProgress copyWith({
    DownloadStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    return DownloadProgress(
      trackId: trackId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
