import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'failure.dart';

/// Centralized mapper translating external and low-level errors into
/// typed [AppException]s and safe [Failure]s.
class ErrorMapper {
  const ErrorMapper._();

  /// Converts any low-level exception into a strongly-typed [AppException].
  static AppException mapToException(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _mapDioException(error, stackTrace);
    }

    if (error is FormatException || error is TypeError) {
      return ParsingException(
        message: 'Data parsing error: $error',
        rawError: error,
        stackTrace: stackTrace,
      );
    }

    if (error.runtimeType.toString().contains('SocketException')) {
      return NetworkException(
        message: 'No internet connection ($error)',
        rawError: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownException(
      message: error.toString(),
      rawError: error,
      stackTrace: stackTrace,
    );
  }

  /// Converts any exception or low-level error into a user-facing [Failure].
  static Failure mapToFailure(Object error) {
    if (error is Failure) {
      return error;
    }

    final appException = mapToException(error);
    return _appExceptionToFailure(appException);
  }

  static AppException _mapDioException(
    DioException dioError,
    StackTrace? stackTrace,
  ) {
    final st = stackTrace ?? dioError.stackTrace;
    final statusCode = dioError.response?.statusCode;

    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutException(
          message: 'Network operation timed out (${dioError.type.name})',
          statusCode: statusCode,
          rawError: dioError,
          stackTrace: st,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message:
              'Connection failed: ${dioError.message ?? "No internet connection"}',
          statusCode: statusCode,
          rawError: dioError,
          stackTrace: st,
        );

      case DioExceptionType.badResponse:
        return _mapStatusCodeToException(statusCode, dioError, st);

      case DioExceptionType.cancel:
        return CancellationException(
          message: 'Request was cancelled',
          statusCode: statusCode,
          rawError: dioError,
          stackTrace: st,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'SSL certificate verification failed',
          statusCode: statusCode,
          rawError: dioError,
          stackTrace: st,
        );

      case DioExceptionType.unknown:
        if (dioError.error is AppException) {
          return dioError.error! as AppException;
        }
        return NetworkException(
          message: dioError.message ?? 'Unknown network communication error',
          statusCode: statusCode,
          rawError: dioError,
          stackTrace: st,
        );
    }
  }

  static AppException _mapStatusCodeToException(
    int? statusCode,
    DioException dioError,
    StackTrace st,
  ) {
    final serverMessage = _extractServerMessage(dioError.response?.data);

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: serverMessage ?? 'Bad request (400)',
          statusCode: 400,
          rawError: dioError,
          stackTrace: st,
        );
      case 401:
        return UnauthorizedException(
          message: serverMessage ?? 'Unauthorized (401)',
          statusCode: 401,
          rawError: dioError,
          stackTrace: st,
        );
      case 403:
        return ForbiddenException(
          message: serverMessage ?? 'Access forbidden (403)',
          statusCode: 403,
          rawError: dioError,
          stackTrace: st,
        );
      case 404:
        return NotFoundException(
          message: serverMessage ?? 'Resource not found (404)',
          statusCode: 404,
          rawError: dioError,
          stackTrace: st,
        );
      case 429:
        return RateLimitException(
          message: serverMessage ?? 'Rate limit exceeded (429)',
          statusCode: 429,
          rawError: dioError,
          stackTrace: st,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: serverMessage ?? 'Server error ($statusCode)',
            statusCode: statusCode,
            rawError: dioError,
            stackTrace: st,
          );
        }
        return UnknownException(
          message: serverMessage ?? 'HTTP error: status $statusCode',
          statusCode: statusCode,
          rawError: dioError,
          stackTrace: st,
        );
    }
  }

  static Failure _appExceptionToFailure(AppException exception) {
    if (exception is NetworkException) {
      return NetworkFailure(originalError: exception);
    }
    if (exception is TimeoutException) {
      return TimeoutFailure(originalError: exception);
    }
    if (exception is ServerException) {
      return ServerFailure(originalError: exception);
    }
    if (exception is NotFoundException) {
      return NotFoundFailure(originalError: exception);
    }
    if (exception is UnauthorizedException || exception is ForbiddenException) {
      return UnauthorizedFailure(originalError: exception);
    }
    if (exception is RateLimitException) {
      return RateLimitFailure(originalError: exception);
    }
    if (exception is BadRequestException) {
      return ValidationFailure(originalError: exception);
    }
    if (exception is ParsingException) {
      return ParsingFailure(originalError: exception);
    }
    if (exception is PlaybackException) {
      return PlaybackFailure(originalError: exception);
    }
    return UnknownFailure(originalError: exception);
  }

  static String? _extractServerMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
    }
    return null;
  }
}
