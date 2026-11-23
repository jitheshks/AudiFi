import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';

/// In-memory prediction and bounded LRU stream URL cache.
/// Maintains the immediate upcoming track's predicted stream URL while retaining
/// recently resolved stream URLs to eliminate duplicate network lookups.
class NextTrackUrlCache {
  String? _predictedTrackId;
  String? _streamUrl;

  /// Bounded LRU cache of recently resolved stream URLs (max 16 entries).
  final Map<String, _StreamCacheEntry> _lruStreamCache = {};
  static const int _maxLruCapacity = 16;
  static const Duration _streamUrlTtl = Duration(minutes: 30);

  /// Returns the cached stream URL if [trackId] matches the predicted track, without consuming it.
  String? peek(String trackId) {
    if (_predictedTrackId == trackId &&
        _streamUrl != null &&
        _streamUrl!.isNotEmpty) {
      return _streamUrl;
    }
    return null;
  }

  /// Stores pre-resolved [streamUrl] for [trackId]. Overwrites any previous prediction.
  void put(String trackId, String streamUrl) {
    if (trackId.isEmpty || streamUrl.isEmpty) return;
    _predictedTrackId = trackId;
    _streamUrl = streamUrl;
    putHistoricalUrl(trackId, streamUrl);
    AppLogger.debug(
      'Cached pre-resolved stream URL for predicted next track: $trackId',
      tag: 'Playback',
    );
  }

  /// Consumes and immediately invalidates the cached stream URL for [trackId].
  /// Returns the cached URL on match, or null on cache miss or track mismatch.
  String? consume(String trackId) {
    if (_predictedTrackId == trackId &&
        _streamUrl != null &&
        _streamUrl!.isNotEmpty) {
      final url = _streamUrl;
      clear(reason: 'consumed_by_playback');
      return url;
    }
    return null;
  }

  /// True if a valid prediction currently exists for [trackId].
  bool has(String trackId) => peek(trackId) != null;

  /// Returns the track ID of the current prediction, if any.
  String? get currentTrackId => _predictedTrackId;

  /// Retrieves a valid, unexpired stream URL from the bounded LRU cache, if present.
  String? getHistoricalUrl(String trackId) {
    final entry = _lruStreamCache[trackId];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _lruStreamCache.remove(trackId);
      return null;
    }

    // Refresh LRU position by re-inserting at end
    _lruStreamCache.remove(trackId);
    _lruStreamCache[trackId] = entry;
    return entry.streamUrl;
  }

  /// Caches a resolved [streamUrl] in the bounded LRU cache.
  void putHistoricalUrl(String trackId, String streamUrl) {
    if (trackId.isEmpty || streamUrl.isEmpty) return;

    if (_lruStreamCache.length >= _maxLruCapacity) {
      final oldestKey = _lruStreamCache.keys.first;
      _lruStreamCache.remove(oldestKey);
    }

    _lruStreamCache[trackId] = _StreamCacheEntry(
      streamUrl: streamUrl,
      expiresAt: DateTime.now().add(_streamUrlTtl),
    );
  }

  /// Clears and invalidates the cached prediction with an optional diagnostic [reason].
  void clear({String reason = 'invalidated'}) {
    if (_predictedTrackId != null) {
      AppLogger.debug(
        'Prediction cache cleared for track: $_predictedTrackId (reason: $reason)',
        tag: 'Playback',
      );
    }
    _predictedTrackId = null;
    _streamUrl = null;
  }

  /// Clears historical LRU cache (e.g. on full cache purge or logout).
  void clearHistorical() {
    _lruStreamCache.clear();
  }
}

class _StreamCacheEntry {
  const _StreamCacheEntry({required this.streamUrl, required this.expiresAt});

  final String streamUrl;
  final DateTime expiresAt;
}

/// Riverpod provider for [NextTrackUrlCache].
final nextTrackUrlCacheProvider = Provider<NextTrackUrlCache>((ref) {
  return NextTrackUrlCache();
});
