import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import 'interceptors/api_error_interceptor.dart';
import 'interceptors/audius_headers_interceptor.dart';
import 'interceptors/safe_logging_interceptor.dart';

/// Centralized HTTP client wrapping [Dio] for network communication with Audius.
class DioClient {
  DioClient({required this.rawDio});

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
    } on DioException catch (e, st) {
      if (e.error is AppException) {
        throw e.error! as AppException;
      }
      throw ErrorMapper.mapToException(e, st);
    } catch (e, st) {
      if (e is AppException) rethrow;
      throw ErrorMapper.mapToException(e, st);
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
    } on DioException catch (e, st) {
      if (e.error is AppException) {
        throw e.error! as AppException;
      }
      throw ErrorMapper.mapToException(e, st);
    } catch (e, st) {
      if (e is AppException) rethrow;
      throw ErrorMapper.mapToException(e, st);
    }
  }
}

/// Riverpod provider for configuring the base [Dio] instance with standard timeouts,
/// base URL, and security/logging interceptors.
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

/// Riverpod provider for the centralized [DioClient].
final dioClientProvider = Provider<DioClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioClient(rawDio: dio);
});
