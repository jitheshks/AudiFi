import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_constants.dart';
import 'api_exceptions.dart';
import 'api_interceptors.dart';

/// Centralized HTTP client wrapping [Dio] for all network communication with Audius.
class ApiClient {
  ApiClient({required this.rawDio});

  /// Underlying [Dio] instance for low-level or streaming operations.
  final Dio rawDio;

  /// Executes a GET request and returns typed response data.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await rawDio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Unexpected network error: $e',
        type: ApiExceptionType.unknown,
        rawError: e,
      );
    }
  }

  /// Executes a POST request and returns typed response data.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await rawDio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Unexpected network error: $e',
        type: ApiExceptionType.unknown,
        rawError: e,
      );
    }
  }
}

/// Riverpod provider for configuring the base [Dio] instance with standard timeouts,
/// base URL, and interceptors.
final dioProvider = Provider<Dio>((ref) {
  final baseOptions = BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    sendTimeout: ApiConstants.sendTimeout,
    responseType: ResponseType.json,
  );

  final dio = Dio(baseOptions);

  dio.interceptors.addAll([
    AudiusHeadersInterceptor(),
    SafeLoggingInterceptor(),
    ApiErrorInterceptor(),
  ]);

  return dio;
});

/// Riverpod provider for the centralized [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(rawDio: dio);
});
