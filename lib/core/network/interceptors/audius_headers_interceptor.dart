import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';

/// Interceptor that attaches default Audius query parameters (such as `app_name`)
/// and required request headers.
class AudiusHeadersInterceptor extends Interceptor {
  AudiusHeadersInterceptor({this.appName = ApiConstants.defaultAppName});

  final String appName;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // In Audius REST API, app_name is standardly passed as a query param
    final updatedQueryParams = Map<String, dynamic>.from(
      options.queryParameters,
    );
    if (!updatedQueryParams.containsKey(ApiConstants.paramAppName)) {
      updatedQueryParams[ApiConstants.paramAppName] = appName;
    }
    options.queryParameters = updatedQueryParams;

    // Standard headers
    options.headers['Accept'] = 'application/json';

    handler.next(options);
  }
}
