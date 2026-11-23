import 'package:dio/dio.dart';

import '../../errors/error_mapper.dart';

/// Interceptor that translates [DioException] into strongly typed [AppException].
class ApiErrorInterceptor extends Interceptor {
  ApiErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = ErrorMapper.mapToException(err);
    final enrichedError = err.copyWith(error: appException);
    handler.next(enrichedError);
  }
}
