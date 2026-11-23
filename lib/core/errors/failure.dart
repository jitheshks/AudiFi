/// Represents safe, application-facing failures consumed by controllers and UI.
abstract class Failure {
  const Failure({
    required this.message,
    required this.code,
    this.context,
    this.originalError,
  });

  /// User-friendly message safe for display on UI.
  final String message;

  /// Categorical error code for programmatic handling (e.g., 'network', 'not_found').
  final String code;

  /// Optional contextual metadata for diagnostics.
  final Map<String, dynamic>? context;

  /// Underlying error or exception for diagnostics (never shown to end-user).
  final Object? originalError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// Safe failure when network connectivity is unavailable.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Unable to connect. Check your internet connection.',
    super.code = 'network',
    super.context,
    super.originalError,
  });
}

/// Safe failure when network operation times out.
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Connection timed out. Please try again.',
    super.code = 'timeout',
    super.context,
    super.originalError,
  });
}

/// Safe failure when server encounters an error or is unreachable.
class ServerFailure extends Failure {
  const ServerFailure({
    super.message =
        'Audius servers are having trouble. Please try again in a few moments.',
    super.code = 'server',
    super.context,
    super.originalError,
  });
}

/// Safe failure when requested content (artist, track, playlist) is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested content could not be found.',
    super.code = 'not_found',
    super.context,
    super.originalError,
  });
}

/// Safe failure when access is unauthorized or forbidden.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'You do not have access to this content.',
    super.code = 'unauthorized',
    super.context,
    super.originalError,
  });
}

/// Safe failure when API rate limits are exceeded.
class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message =
        'Audius is busy right now. Please wait a moment before trying again.',
    super.code = 'rate_limit',
    super.context,
    super.originalError,
  });
}

/// Safe failure for invalid input or request validation errors.
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Invalid request. Please verify your input.',
    super.code = 'validation',
    super.context,
    super.originalError,
  });
}

/// Safe failure when data parsing or response mapping fails.
class ParsingFailure extends Failure {
  const ParsingFailure({
    super.message = 'Unable to process server response.',
    super.code = 'parsing',
    super.context,
    super.originalError,
  });
}

/// Safe failure when audio playback or streaming fails.
class PlaybackFailure extends Failure {
  const PlaybackFailure({
    super.message = 'Unable to play this audio stream. Please try again.',
    super.code = 'playback',
    super.context,
    super.originalError,
  });
}

/// Safe failure for unclassified or unexpected exceptions.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Something went wrong. Please try again.',
    super.code = 'unknown',
    super.context,
    super.originalError,
  });
}
