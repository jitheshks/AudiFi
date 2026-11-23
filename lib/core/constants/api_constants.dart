/// Centralized API constants based strictly on the official Audius OpenAPI specification
/// located in `references/api/api.json`.
abstract final class ApiConstants {
  /// Verified production base URL from the Audius OpenAPI specification:
  /// `servers: [{'url': 'https://api.audius.co/v1', 'description': 'Production'}]`
  static const String baseUrl = 'https://api.audius.co/v1';

  /// Standard app identifier for Audius API rate limiting and metrics.
  static const String defaultAppName = 'AudiFi';

  /// Canonical privacy policy URL hosted for store compliance and transparency disclosures.
  /// Configurable at build time via `--dart-define=PRIVACY_POLICY_URL=https://...`.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://jklabs-apps.github.io/audifi/privacy-policy.html',
  );

  /// Whether a valid production privacy policy URL has been configured.
  static bool get hasPrivacyPolicyUrl =>
      privacyPolicyUrl.isNotEmpty &&
      Uri.tryParse(privacyPolicyUrl)?.hasScheme == true;

  /// Network timeout configurations.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Common Query Parameter Keys verified against api.json
  static const String paramAppName = 'app_name';
  static const String paramApiKey = 'api_key';
  static const String paramLimit = 'limit';
  static const String paramOffset = 'offset';
  static const String paramQuery = 'query';
  static const String paramGenre = 'genre';
  static const String paramTime = 'time';
  static const String paramUserId = 'user_id';
  static const String paramUrl = 'url';
  static const String paramKind = 'kind';
  static const String paramType = 'type';
  static const String paramIncludePurchaseable = 'includePurchaseable';
  static const String paramIncludePurchase = 'include_purchase';

  // Common Parameter Default Values
  static const int defaultLimit = 20;
  static const int defaultOffset = 0;
  static const String defaultTimeRange = 'week';
}
