/// Base application exception hierarchy representing technical/infrastructure errors.
abstract class AppException implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
    this.rawError,
    this.stackTrace,
  });

  /// Technical diagnostic message.
  final String message;

  /// Optional HTTP status code or platform error code.
  final int? statusCode;

  /// Underlying raw exception or error object.
  final Object? rawError;

  /// Captured stack trace.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final codeStr = statusCode != null ? ' (Status: $statusCode)' : '';
    return '$runtimeType$codeStr: $message';
  }
}

/// Thrown when device lacks network connectivity or socket connection fails.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No network connectivity available',
    super.statusCode,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when network connect, send, or receive operations time out.
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Network operation timed out',
    super.statusCode,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when server responds with 5xx internal server errors.
class ServerException extends AppException {
  const ServerException({
    super.message = 'Remote server encountered an error',
    super.statusCode = 500,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when requested resource does not exist (HTTP 404).
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Requested resource was not found',
    super.statusCode = 404,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when user or client lacks authentication credentials (HTTP 401).
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Authentication required',
    super.statusCode = 401,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when user or client lacks permissions for the action (HTTP 403).
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Access forbidden for this resource',
    super.statusCode = 403,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when request violates rate limiting rules (HTTP 429).
class RateLimitException extends AppException {
  const RateLimitException({
    super.message = 'API rate limit exceeded. Please wait before retrying.',
    super.statusCode = 429,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when client sends bad request parameters or syntax (HTTP 400).
class BadRequestException extends AppException {
  const BadRequestException({
    super.message = 'Invalid request parameters',
    super.statusCode = 400,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when JSON deserialization, decoding, or schema mapping fails.
class ParsingException extends AppException {
  const ParsingException({
    super.message = 'Failed to parse data response',
    super.statusCode,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when local storage or cache reading/writing fails.
class CacheException extends AppException {
  const CacheException({
    super.message = 'Local cache operation failed',
    super.statusCode,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when audio playback, stream decoding, or player engine fails.
class PlaybackException extends AppException {
  const PlaybackException({
    super.message = 'Audio playback engine error',
    super.statusCode,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown when an asynchronous operation is explicitly cancelled.
class CancellationException extends AppException {
  const CancellationException({
    super.message = 'Operation was cancelled',
    super.statusCode,
    super.rawError,
    super.stackTrace,
  });
}

/// Thrown for unclassified or unexpected exceptions.
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred',
    super.statusCode,
    super.rawError,
    super.stackTrace,
  });
}
