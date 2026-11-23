import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

/// Categories of API and network failures.
enum ApiExceptionType {
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  badCertificate,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  cancel,
  connectionError,
  format,
  unknown,
}

/// Strongly-typed exception class representing network and Audius API errors.
class ApiException extends AppException {
  const ApiException({
    required super.message,
    required this.type,
    super.statusCode,
    super.rawError,
  });

  /// Semantic error category.
  final ApiExceptionType type;

  /// Constructs an [ApiException] mapped from a [DioException].
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message:
              'Connection timed out. Please check your internet connection.',
          type: ApiExceptionType.connectionTimeout,
          statusCode: error.response?.statusCode,
          rawError: error,
        );

      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Request send timed out. Please try again.',
          type: ApiExceptionType.sendTimeout,
          statusCode: error.response?.statusCode,
          rawError: error,
        );

      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Server response timed out. Please try again.',
          type: ApiExceptionType.receiveTimeout,
          statusCode: error.response?.statusCode,
          rawError: error,
        );

      case DioExceptionType.transformTimeout:
        return ApiException(
          message: 'Request transformation timed out.',
          type: ApiExceptionType.sendTimeout,
          statusCode: error.response?.statusCode,
          rawError: error,
        );

      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Security certificate error encountered.',
          type: ApiExceptionType.badCertificate,
          statusCode: error.response?.statusCode,
          rawError: error,
        );

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return _mapStatusCode(status, error);

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          type: ApiExceptionType.cancel,
          statusCode: error.response?.statusCode,
          rawError: error,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection detected. Please verify network settings.',
          type: ApiExceptionType.connectionError,
          statusCode: error.response?.statusCode,
          rawError: error,
        );

      case DioExceptionType.unknown:
        return ApiException(
          message: 'An unexpected network error occurred.',
          type: ApiExceptionType.unknown,
          statusCode: error.response?.statusCode,
          rawError: error,
        );
    }
  }

  static ApiException _mapStatusCode(int? status, DioException error) {
    switch (status) {
      case 400:
        return ApiException(
          message:
              'Bad request. Please verify the submitted request parameters.',
          type: ApiExceptionType.badRequest,
          statusCode: 400,
          rawError: error,
        );
      case 401:
        return ApiException(
          message:
              'Unauthorized. Authentication or valid API credentials required.',
          type: ApiExceptionType.unauthorized,
          statusCode: 401,
          rawError: error,
        );
      case 403:
        return ApiException(
          message: 'Access forbidden for this resource.',
          type: ApiExceptionType.forbidden,
          statusCode: 403,
          rawError: error,
        );
      case 404:
        return ApiException(
          message: 'The requested resource was not found on Audius.',
          type: ApiExceptionType.notFound,
          statusCode: 404,
          rawError: error,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message:
              'Audius server is currently unavailable. Please try again later.',
          type: ApiExceptionType.serverError,
          statusCode: status,
          rawError: error,
        );
      default:
        return ApiException(
          message: 'Received unexpected response status code ($status).',
          type: ApiExceptionType.unknown,
          statusCode: status,
          rawError: error,
        );
    }
  }

  @override
  String toString() =>
      'ApiException(type: $type, statusCode: $statusCode, message: $message)';
}
