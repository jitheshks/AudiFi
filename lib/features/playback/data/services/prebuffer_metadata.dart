import 'dart:io';

/// Metadata describing a bounded audio prebuffer file stored in temporary storage.
class PrebufferMetadata {
  const PrebufferMetadata({
    required this.trackId,
    required this.filePath,
    required this.bufferedBytes,
    required this.createdAt,
    this.totalBytes,
    required this.streamUrl,
    this.contentType = 'audio/mpeg',
    this.isComplete = true,
  });

  /// The unique track identifier.
  final String trackId;

  /// Absolute file system path to the `.buf` file.
  final String filePath;

  /// Actual number of audio bytes saved in this prebuffer file.
  final int bufferedBytes;

  /// Total audio content length in bytes if determined from Content-Range/Content-Length.
  final int? totalBytes;

  /// The resolved stream URL that was used to fetch this prebuffer.
  final String streamUrl;

  /// Timestamp when the prebuffer was created and finalized.
  final DateTime createdAt;

  /// Content-Type header (defaults to 'audio/mpeg').
  final String contentType;

  /// Whether the target prebuffer byte size or full track stream was reached.
  final bool isComplete;

  /// Returns the underlying [File] handle on the local file system.
  File get file => File(filePath);

  /// Checks if the prebuffer file actually exists and contains audio data.
  bool get isValid {
    final f = file;
    return f.existsSync() && f.lengthSync() > 0 && bufferedBytes > 0;
  }

  /// Whether this prebuffer has exceeded its maximum validity window [ttl].
  bool isExpired([Duration ttl = const Duration(minutes: 30)]) {
    return DateTime.now().difference(createdAt) > ttl;
  }
}
