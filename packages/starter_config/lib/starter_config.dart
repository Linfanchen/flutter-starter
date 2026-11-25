/// Deployment labels supported by the starter templates.
enum AppEnvironment { dev, staging, prod }

/// Explains an invalid configuration key without printing its supplied value.
final class ConfigException implements Exception {
  const ConfigException(this.key, this.message);

  final String key;
  final String message;

  @override
  String toString() => '$key: $message';
}

/// Validated settings for composing sample or remote application services.
final class AppConfig {
  const AppConfig._(this.environment, this.apiBaseUrl, this.useSampleData);

  final AppEnvironment environment;
  final Uri? apiBaseUrl;
  final bool useSampleData;

  /// Parses compile-time defaults and a product-specific API setting.
  ///
  /// [environment] and [sampleData] can be supplied directly in tests.
  factory AppConfig.parse({
    required String apiKey,
    required String apiUrl,
    String environment =
        const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
    String sampleData = const String.fromEnvironment('APP_USE_SAMPLE_DATA'),
  }) {
    final deployment = switch (environment) {
      'dev' => AppEnvironment.dev,
      'staging' => AppEnvironment.staging,
      'prod' => AppEnvironment.prod,
      _ => throw const ConfigException('APP_ENV', 'Use dev, staging or prod.'),
    };
    final uri = apiUrl.isEmpty ? null : Uri.tryParse(apiUrl);
    if (apiUrl.isNotEmpty &&
        (uri == null ||
            !{'http', 'https'}.contains(uri.scheme) ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty ||
            uri.hasQuery ||
            uri.hasFragment ||
            apiUrl.contains(RegExp(r'\s')))) {
      throw ConfigException(apiKey,
          'Use an HTTP(S) base URL without credentials, query or fragment.');
    }
    final samples = switch (sampleData) {
      '' => uri == null,
      'true' => true,
      'false' => false,
      _ => throw const ConfigException(
          'APP_USE_SAMPLE_DATA', 'Use true or false.'),
    };
    if (!samples && uri == null) {
      throw ConfigException(
          apiKey, 'Set a base URL when sample data is disabled.');
    }
    return AppConfig._(deployment, uri, samples);
  }
}
