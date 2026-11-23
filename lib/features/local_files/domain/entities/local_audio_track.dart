import '../../../artists/domain/entities/user.dart';
import '../../../tracks/domain/entities/track.dart';

/// Pure domain entity modeling a local audio track imported by the user
/// from their device storage into Audifi's managed collection.
class LocalAudioTrack {
  const LocalAudioTrack({
    required this.track,
    required this.localFilePath,
    required this.fileSizeBytes,
    required this.importedAt,
    required this.fileExtension,
  });

  /// The underlying domain [Track] representation for playback and queues.
  final Track track;

  /// Absolute filesystem path to Audifi's app-managed audio file copy.
  final String localFilePath;

  /// File size in bytes.
  final int fileSizeBytes;

  /// When the audio file was imported.
  final DateTime importedAt;

  /// File extension format (e.g. `mp3`, `m4a`, `flac`, `wav`, `aac`, `ogg`).
  final String fileExtension;

  /// Human-readable formatted file size string (e.g. `4.2 MB`).
  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'trackId': track.id,
      'title': track.title,
      'artistName': track.user?.name ?? 'Local Artist',
      'duration': track.duration,
      'localFilePath': localFilePath,
      'fileSizeBytes': fileSizeBytes,
      'importedAt': importedAt.toIso8601String(),
      'fileExtension': fileExtension,
    };
  }

  factory LocalAudioTrack.fromJson(Map<String, dynamic> json) {
    final trackId = json['trackId'] as String;
    final title = json['title'] as String;
    final artistName = json['artistName'] as String? ?? 'Local Artist';
    final duration = (json['duration'] as num?)?.toInt() ?? 0;

    return LocalAudioTrack(
      track: Track(
        id: trackId,
        title: title,
        duration: duration,
        user: User(
          id: 'local_artist_${trackId.hashCode}',
          name: artistName,
          handle: 'local',
        ),
        isStreamable: true,
        isDownloadable: false,
      ),
      localFilePath: json['localFilePath'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      importedAt:
          DateTime.tryParse(json['importedAt'] as String? ?? '') ??
          DateTime.now(),
      fileExtension: json['fileExtension'] as String? ?? 'mp3',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAudioTrack &&
          runtimeType == other.runtimeType &&
          track.id == other.track.id;

  @override
  int get hashCode => track.id.hashCode;

  @override
  String toString() =>
      'LocalAudioTrack(id: ${track.id}, title: ${track.title}, path: $localFilePath)';
}
