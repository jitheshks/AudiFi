// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:just_audio/just_audio.dart';

import '../../../../core/logging/app_logger.dart';

/// Custom [StreamAudioSource] that serves an initial prefix of audio bytes
/// directly from a local prebuffered file, and then seamlessly continues
/// streaming the remainder of the track from a remote HTTP URL if online.
///
/// If offline, it plays the locally available prebuffered bytes and completes
/// gracefully when the buffered data is exhausted.
class PrebufferedAudioSource extends StreamAudioSource {
  PrebufferedAudioSource({
    required this.trackId,
    required this.prebufferedFile,
    required this.prebufferedBytes,
    required this.remoteUri,
    this.totalContentLength,
    this.urlResolver,
    this.contentType = 'audio/mpeg',
    this.onOfflineExhausted,
    super.tag,
  });

  final String trackId;
  final File prebufferedFile;
  final int prebufferedBytes;
  final int? totalContentLength;
  final Uri remoteUri;
  final Future<String> Function()? urlResolver;
  final String contentType;
  final void Function(String trackId)? onOfflineExhausted;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final startOffset = start ?? 0;
    final endOffset = end;

    AppLogger.debug(
      'PrebufferedAudioSource.request(start=$startOffset, end=$endOffset, prebuffered=$prebufferedBytes, total=$totalContentLength)',
      tag: 'Playback',
    );

    // 1. Seeking or requesting beyond the local prebuffer (start >= prebufferedBytes)
    if (startOffset >= prebufferedBytes) {
      return _handleRemoteRangeRequest(startOffset, endOffset);
    }

    // 2. Request starts within the prebuffered local bytes (start < prebufferedBytes)
    final localEnd = min(endOffset ?? prebufferedBytes, prebufferedBytes);
    final localStream = prebufferedFile.openRead(startOffset, localEnd);

    // If request is strictly satisfied by the local prebuffer (e.g. ExoPlayer probing header)
    if (endOffset != null && endOffset <= prebufferedBytes) {
      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: totalContentLength,
        contentLength: localEnd - startOffset,
        offset: startOffset,
        contentType: contentType,
        stream: localStream,
      );
    }

    // Full playback or request extends beyond the local prebuffer:
    // Yield local prefix first, then seamlessly continue online if available.
    final combinedStream = _combineLocalAndRemoteStreams(
      localStream: localStream,
      remoteStartOffset: prebufferedBytes,
      remoteEndOffset: endOffset,
    );

    final contentLength = totalContentLength != null
        ? (endOffset != null
              ? endOffset - startOffset
              : totalContentLength! - startOffset)
        : null;

    return StreamAudioResponse(
      rangeRequestsSupported: true,
      sourceLength: totalContentLength,
      contentLength: contentLength,
      offset: startOffset,
      contentType: contentType,
      stream: combinedStream,
    );
  }

  /// Combines local prebuffered file stream with an asynchronous HTTP continuation stream.
  Stream<List<int>> _combineLocalAndRemoteStreams({
    required Stream<List<int>> localStream,
    required int remoteStartOffset,
    required int? remoteEndOffset,
  }) async* {
    AppLogger.debug(
      'PrebufferedAudioSource: streaming local prefix ($remoteStartOffset bytes) for $trackId',
      tag: 'Playback',
    );

    // 1. Stream all available local prebuffered bytes
    await for (final chunk in localStream) {
      yield chunk;
    }

    AppLogger.debug(
      'PrebufferedAudioSource: local prefix exhausted for $trackId; attempting online continuation at byte $remoteStartOffset',
      tag: 'Playback',
    );

    // 2. Seamlessly continue streaming from remote HTTP endpoint if online
    Stream<List<int>>? remoteStream;
    try {
      remoteStream = await _openRemoteHttpStream(
        remoteStartOffset,
        remoteEndOffset,
      );
    } catch (e) {
      AppLogger.info(
        'PrebufferedAudioSource: network unavailable for continuation of $trackId ($e). Gracefully ending prebuffer stream.',
        tag: 'Playback',
      );
      onOfflineExhausted?.call(trackId);
      return;
    }

    try {
      await for (final chunk in remoteStream) {
        yield chunk;
      }
    } catch (e) {
      AppLogger.info(
        'PrebufferedAudioSource: remote continuation interrupted for $trackId ($e)',
        tag: 'Playback',
      );
      onOfflineExhausted?.call(trackId);
    }
  }

  /// Handles requests where startOffset is already beyond the prebuffered region (e.g. seek).
  Future<StreamAudioResponse> _handleRemoteRangeRequest(
    int startOffset,
    int? endOffset,
  ) async {
    try {
      final stream = await _openRemoteHttpStream(startOffset, endOffset);
      final contentLength = totalContentLength != null
          ? (endOffset != null
                ? endOffset - startOffset
                : totalContentLength! - startOffset)
          : null;

      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: totalContentLength,
        contentLength: contentLength,
        offset: startOffset,
        contentType: contentType,
        stream: stream,
      );
    } catch (e) {
      AppLogger.warning(
        'PrebufferedAudioSource: remote range request failed ($startOffset-$endOffset): $e',
        tag: 'Playback',
      );
      // Return empty stream so player handles EOF rather than crashing
      return StreamAudioResponse(
        rangeRequestsSupported: true,
        sourceLength: totalContentLength,
        contentLength: 0,
        offset: startOffset,
        contentType: contentType,
        stream: const Stream.empty(),
      );
    }
  }

  /// Opens an HTTP Range GET request for bytes [startOffset] to [endOffset].
  /// Supports retrying once with [urlResolver] on 401/403 (expired signed URL).
  Future<Stream<List<int>>> _openRemoteHttpStream(
    int startOffset,
    int? endOffset, {
    bool isRetry = false,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    Uri targetUri = remoteUri;
    if (isRetry && urlResolver != null) {
      final freshUrl = await urlResolver!();
      targetUri = Uri.parse(freshUrl);
      AppLogger.info(
        'PrebufferedAudioSource: re-resolved fresh URL for expired stream: $trackId',
        tag: 'Playback',
      );
    }

    try {
      final request = await client.getUrl(targetUri);
      final rangeHeader =
          'bytes=$startOffset-${endOffset != null ? endOffset - 1 : ''}';
      request.headers.set(HttpHeaders.rangeHeader, rangeHeader);
      request.headers.set(HttpHeaders.acceptHeader, '*/*');

      final response = await request.close();

      // Handle signed URL expiration (401/403)
      if ((response.statusCode == 401 || response.statusCode == 403) &&
          !isRetry &&
          urlResolver != null) {
        client.close();
        return await _openRemoteHttpStream(
          startOffset,
          endOffset,
          isRetry: true,
        );
      }

      if (response.statusCode != 200 && response.statusCode != 206) {
        client.close();
        throw HttpException(
          'HTTP Range error: ${response.statusCode} (${response.reasonPhrase})',
          uri: targetUri,
        );
      }

      return response;
    } catch (e) {
      client.close();
      rethrow;
    }
  }
}
