import '../../../tracks/data/models/track_model.dart';
import '../../../tracks/domain/entities/track.dart';

/// Pure domain entity representing a locally downloaded track on device storage.
class DownloadedTrack {
  const DownloadedTrack({
    required this.track,
    required this.localFilePath,
    required this.fileSizeBytes,
    required this.downloadedAt,
  });

  /// Full metadata of the downloaded Audius track.
  final Track track;

  /// Absolute file system path where the MP3 file is stored on the device.
  final String localFilePath;

  /// Size of the downloaded audio file in bytes.
  final int fileSizeBytes;

  /// Timestamp when the download completed.
  final DateTime downloadedAt;

  /// Human-readable file size (e.g. "8.4 MB").
  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'track': track is TrackModel
          ? (track as TrackModel).toJson()
          : TrackModel.fromEntity(track).toJson(),
      'local_file_path': localFilePath,
      'file_size_bytes': fileSizeBytes,
      'downloaded_at': downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedTrack.fromJson(Map<String, dynamic> json) {
    return DownloadedTrack(
      track: TrackModel.fromJson(json['track'] as Map<String, dynamic>),
      localFilePath: json['local_file_path'] as String,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      downloadedAt: json['downloaded_at'] != null
          ? DateTime.tryParse(json['downloaded_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
