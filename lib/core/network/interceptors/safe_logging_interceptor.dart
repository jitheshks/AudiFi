import 'package:dio/dio.dart';

import '../../logging/app_logger.dart';

/// Network logging interceptor that safely logs HTTP traffic through [AppLogger]
/// while redacting sensitive headers, tokens, and query parameters.
class SafeLoggingInterceptor extends Interceptor {
  SafeLoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final sanitizedUri = AppLogger.redactSensitive(options.uri.toString());
    AppLogger.debug(
      '[HTTP Request] ${options.method} $sanitizedUri',
      tag: 'Network',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sanitizedUri = AppLogger.redactSensitive(
      response.requestOptions.uri.toString(),
    );
    AppLogger.debug(
      '[HTTP Response] ${response.statusCode} $sanitizedUri',
      tag: 'Network',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sanitizedUri = AppLogger.redactSensitive(
      err.requestOptions.uri.toString(),
    );
    AppLogger.warning(
      '[HTTP Error] ${err.response?.statusCode ?? 'NO_STATUS'} $sanitizedUri: ${err.message}',
      tag: 'Network',
      error: err,
    );
    handler.next(err);
  }
}
